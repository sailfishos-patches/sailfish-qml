/*
 * Copyright (c) 2012 - 2020 Jolla Ltd.
 * Copyright (c) 2019 - 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.1
import Sailfish.Silica 1.0
import Sailfish.Contacts 1.0
import Sailfish.Telephony 1.0
import Nemo.Configuration 1.0
import org.nemomobile.contacts 1.0
import org.nemomobile.commhistory 1.0

import "callhistory"
import "../common/CallHistory.js" as CallHistory
import "../common"

SilicaListView {
    id: root

    property Item contextMenu
    property alias showDetails: showDetailsConfig.value

    // Declared this way to enable mocking in tests
    property var commCallModel: CommCallModel {
        groupBy: CommCallModel.GroupByContact
        _limit: 200
    }

    function reset() {
        positionViewAtBeginning()
        if (contextMenu !== null)
            contextMenu.close()
    }

    function openContactCard(person, remoteUid) {
        if (person) {
            pageStack.animatorPush("Sailfish.Contacts.ContactCardPage",
                                   { "contact": person, "activeDetail": remoteUid })
        } else {
            var contact = ContactCreator.createContact({"phoneNumbers": [remoteUid]})
            pageStack.animatorPush("Sailfish.Contacts.TemporaryContactCardPage",
                                   { "contact": contact, "activeDetail": remoteUid })
        }
    }

    function dial(remoteUid, modemPath) {
        commCallModel.bufferInsertions = true
        touchBlockTimer.start()
        telephony.dial(remoteUid, modemPath)
    }

    Component.onCompleted: {
        main.commCallModel = commCallModel
        if (!ContactsUtil.isInitialized)
            ContactsUtil.init(Person)
    }

    CommHistoryService {
        id: commHistory
    }

    // mainUIActive is used because Qt.application.active may be true when the calling dialog is active.
    readonly property bool isActive: Qt.application.active && main.mainUIActive && main.mainPage.status === PageStatus.Active
    onIsActiveChanged: {
        if (isActive)
            markReadTimer.start()
        else
            commHistory.callHistoryObserved = false
    }

    Timer {
        id: markReadTimer
        interval: 3000
        repeat: false
        onTriggered: {
            if (root.isActive) {
                commHistory.callHistoryObserved = true
                commCallModel.markAllRead()
            }
        }
    }

    SimManager {
        id: simManager
        controlType: SimManagerType.Voice
    }

    objectName: "callHistoryPage"

    width: parent.width
    height: parent.height

    // Changing header height in an empty view forces fixup animation
    // which interferes with menu closing. Add a dummy item when empty.
    model: commCallModel.count ? commCallModel : dummyModel
    ListModel { id: dummyModel; ListElement { dummy: true } }

    focus: true
    currentIndex: -1

    PullDownMenu {
        MenuItem {
            //: Hide details, show just basic call history
            //% "Show essentials"
            text: showDetails ? qsTrId("voicecall-me-show_essentials")
                              : //% "Show details"
                                qsTrId("voicecall-me-show_details")

            onClicked: showDetails = !showDetails
        }
    }

    Column {
        width: parent.width
        spacing: 2 * Theme.paddingLarge
        anchors.verticalCenter: parent.verticalCenter
        enabled: telephony.callingPermitted && !commCallModel.count && commCallModel.populated
        opacity: enabled ? 1.0 : 0.0
        Behavior on opacity { FadeAnimator {}}
        InfoLabel {
            //: View placeholder shown when the call history view is empty
            //% "You don't have any calls yet"
            text: qsTrId("voicecall-la-no_calls_yet")
        }
        Button {
            //% "Make a call"
            text: qsTrId("voicecall-bt-make_call")
            anchors.horizontalCenter: parent.horizontalCenter
            onClicked: main.mainPage.switchToDialer(TabViewAction.Animated)
        }
    }

    delegate: CallHistoryItem {
        id: wrapper
        objectName: "callHistoryItem"

        showDetails: root.showDetails
        width: ListView.view.width
        opacity: people.populated ? 1.0 : 0.0
        Behavior on opacity { FadeAnimator {} }
        visible: model != null && !model.dummy
        time: model != null && model.startTime != undefined ? model.startTime : main.today
        call: model
        remoteUid: model != null ? model.remoteUid : ""
        // Re-evaluate if the contacts property changes
        person: {
            if (model && model.contactIds != null && model.contactIds != undefined && model.contactIds.length) {
                return people.personById(model.contactIds[0])
            } else {
                return null
            }
        }
        showNumberDetail: true
        subscriberIdentity: model.subscriberIdentity || ''

        function remove() {
            remorseDelete(function() { commCallModel.deleteAt(model.index) })
        }

        ListView.onRemove: animateRemoval()
        onClicked: {
            if (!highlighted && !privateNumber) {
                if (quickCall) {
                    if (telephony.promptForSim(remoteUid)) {
                        openMenu({ 'simSelectorActive': true })
                    } else {
                        dial(remoteUid)
                    }
                } else {
                    openContactCard(person, remoteUid)
                }
                commHistory.callHistoryObserved = true
                commCallModel.markAllRead()
            }
        }

        menu: Component {
            id: menuComponent

            ReminderContextMenu {
                id: contextMenu
                property alias simSelectorActive: simSelector.active
                Component.onCompleted: root.contextMenu = contextMenu

                showReminderOptions: false

                number: showReminderOptions ? wrapper.remoteUid : ""
                person: showReminderOptions ? wrapper.person : null

                SimPickerMenuItem {
                    id: simSelector
                    menu: contextMenu
                    fadeAnimationEnabled: !quickCall
                    onTriggerAction: dial(remoteUid, modemPath)
                }

                Item {
                    width: 1; height: Theme.paddingSmall
                    visible: callDetailsRow.visible
                }

                CallDetailsRow {
                    id: callDetailsRow
                    visible: hasVisibleContent
                    // If details are shown delegate don't anymore show on menu
                    showDetails: !root.showDetails
                }

                MenuItem {
                    visible: !privateNumber && !quickCall && telephony.callingPermitted
                    //% "Call"
                    text: qsTrId("voicecall-me-call")
                    onClicked: {
                        if (telephony.promptForSim(remoteUid)) {
                            simSelector.active = true
                        } else {
                            dial(remoteUid)
                        }
                    }
                }
                MenuItem {
                    visible: !privateNumber && telephony.messagingPermitted
                    objectName: "smsMenuItem"
                    //% "Send message"
                    text: qsTrId("voicecall-me-send_message")
                    onClicked: {
                        messaging.startSMS(model.remoteUid)
                    }
                }
                MenuItem {
                    visible: !privateNumber && quickCall
                    objectName: "contactCardMenuItem"
                    text: {
                        //% "Open contact card"
                        wrapper.person ? qsTrId("voicecall-me-open_contact_card")
                                 //% "Save as contact"
                               : qsTrId("voicecall-me-save-contact")
                    }
                    onClicked: {
                        if (wrapper.person) {
                            openContactCard(wrapper.person, model.remoteUid)
                        } else {
                            // Hide existing menu items
                            var content = contextMenu._contentColumn
                            for (var i = 0; i < content.children.length; i++) {
                                content.children[i].visible = false
                            }

                            // block menu closing
                            contextMenu.closeOnActivation = false

                            // reset highlight
                            contextMenu._setHighlightedItem(null)

                            // Add sub-menu menu items
                            contactSaveOptions.createObject(contextMenu, { menu: contextMenu, remoteUid: model.remoteUid })
                        }
                    }
                }
                MenuItem {
                    visible: !privateNumber && !wrapper.person
                    //% "Copy"
                    text: qsTrId("voicecall-me-copy")
                    onClicked: Clipboard.text = model.remoteUid
                }
                MenuItem {
                    visible: !wrapper.reminder.exists && telephony.callingPermitted
                    //: Add a reminder to call this contact
                    //% "Add call reminder"
                    text: qsTrId("voicecall-me-add_call_reminder")

                    onClicked: {
                        // Hide existing menu items
                        var content = contextMenu._contentColumn
                        for (var i = 0; i < content.children.length; i++) {
                            content.children[i].visible = false
                        }

                        // block menu closing
                        contextMenu.closeOnActivation = false

                        // reset highlight
                        contextMenu._setHighlightedItem(null)

                        contextMenu.showReminderOptions = true
                    }
                }

                MenuItem {
                    objectName: "deleteMenuItem"

                    text: {
                        if (wrapper.reminder.exists) {
                            return root.showDetails
                                      //: Remove a call reminder from a recent call entry.
                                      //% "Remove reminder"
                                    ? qsTrId("voicecall-me-remove_reminder")
                                      //: Remove a call reminder from a recent call entry. %1 = the reminder alert time
                                      //% "Remove reminder (%1)"
                                    : qsTrId("voicecall-me-remove_reminder_with_time").arg(Format.formatDate(wrapper.reminder.when, Formatter.TimeValue))
                        } else {
                            //: Remove all entries for this contact from the list of recent calls
                            //% "Clear contact history"
                            return qsTrId("voicecall-me-clear_contact_history")
                        }
                    }

                    onClicked: {
                        if (wrapper.reminder.exists) {
                            wrapper.reminder.remove()
                        } else {
                            remove()
                        }
                    }
                }
            }
        }
    }

    Component {
        id: contactSaveOptions
        Item {
            id: _contactSaveOptions
            property Item menu
            property string remoteUid

            MenuItem {
                //% "Create new contact"
                text: qsTrId("voicecall-me-create_new_contact")
                parent: menu._contentColumn // context menu touch requires menu items are children of content area
                onClicked: {
                    main.mainPage.saveAsContact(remoteUid)
                    menu.close()
                }
            }

            MenuItem {
                //% "Link to contact"
                text: qsTrId("voicecall-me-link_to_contact")
                parent: menu._contentColumn // context menu touch requires menu items are children of content area
                onClicked: {
                    main.mainPage.linkToContact(remoteUid)
                    menu.close()
                }
            }

            Connections {
                target: menu
                onClosed: _contactSaveOptions.destroy()
            }
        }
    }

    VerticalScrollDecorator {}

    BusyIndicator {
        y: Screen.height/3 - height/2
        Behavior on y { NumberAnimation { easing.type: Easing.InOutQuad; duration: 200 } }
        size: BusyIndicatorSize.Large
        parent: root.contentItem
        anchors.horizontalCenter: parent.horizontalCenter
        running: !commCallModel.populated || !people.populated
    }

    ConfigurationValue {
        id: showDetailsConfig
        key: "/jolla/voicecall/callhistory/show_details"
        defaultValue: false
    }

    TouchBlocker {
        anchors.fill: parent
        enabled: touchBlockTimer.running
        Timer {
            id: touchBlockTimer
            interval: 2000
            onTriggered: commCallModel.bufferInsertions = false
        }
    }

    // If call attempt fails immediatelly stop the blocking
    Connections {
        ignoreUnknownSignals: true
        target: touchBlockTimer.running ? telephony : null
        onCallError: {
            touchBlockTimer.stop()
            commCallModel.bufferInsertions = false
        }
    }
}
