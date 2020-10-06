/**
 * Copyright (c) 2019 Jolla Ltd.
 * Copyright (c) 2019 - 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Contacts 1.0
import Sailfish.Silica.private 1.0
import com.jolla.settings.system 1.0
import org.nemomobile.contacts 1.0
import org.nemomobile.systemsettings 1.0
import Nemo.Configuration 1.0

Page {
    id: root

    property bool quickCall: telephony.callingPermitted && quickCallConfig.value
    signal reset
    clip: true

    function switchToCallHistory() {
        tabs.moveTo(1, TabViewAction.Immediate)
    }

    function switchToDialer(tabViewAction) {
        // pop until main page is on top
        if (root !== pageStack.currentPage) {
            pageStack.pop(root, PageStackAction.Immediate)
        }
        tabs.moveTo(0, tabViewAction)
        main.activate()
    }

    function saveAsContact(remoteUid) {
        ContactsUtil.editContact(ContactCreator.createContact({"phoneNumbers": [remoteUid]}), people, pageStack)
    }

    function linkToContact(remoteUid) {
        var props = {
            allContactsModel: ContactModelCache.unfilteredModel(),
            temporaryContact: ContactCreator.createContact({"phoneNumbers": [remoteUid]})
        }
        pageStack.animatorPush("Sailfish.Contacts.TemporaryContactLinkPage", props)
    }

    AboutSettings {
        id: aboutSettings
    }

    ConfigurationValue {
        id: quickCallConfig
        key: "/jolla/voicecall/quickcall"
        defaultValue: true
    }

    TabView {
        id: tabs

        anchors.fill: parent
        currentIndex: 1

        header: Column {
            width: parent.width

            TabButtonRow {
                Repeater {
                    model: [
                        //: Title of Phone tab page showing number keypad to dial calls
                        //% "Dialer"
                        qsTrId("voicecall-he-dialer"),
                        //: Title of Phone tab page showing call history list
                        //% "History"
                        qsTrId("voicecall-he-history"),
                        //: Title of Phone tab page showing contacts to call to
                        //% "People"
                        qsTrId("voicecall-he-people")
                    ]

                    TabButton {
                        onClicked: tabs.moveTo(model.index)

                        title: modelData
                        tabIndex: model.index
                    }
                }
            }

            Column {
                width: parent.width
                spacing: Theme.paddingMedium * disabledBanner.opacity

                DisabledByMdmBanner {
                    id: disabledBanner
                    clip: true
                    active: !telephony.callingPermitted ||
                            (simFiltersHelper.ready &&
                             (!simFiltersHelper.activeSimCount ||
                              !simFiltersHelper.anyActiveSimCanDial ||
                              !simFiltersHelper.anyActiveSimCanReceive))
                    compressed: true

                    text: {
                        if (!telephony.callingPermitted) {
                            //: Banner shown to the user when they are missing permission to make calls
                            //% "Emergency calls only, outgoing calls disabled by user permissions"
                            return qsTrId("voicecall-la-no_user_permission")
                        } else if (!simFiltersHelper.activeSimCount) {
                            //: Banner shown to the user when there are no active SIM cards inserted
                            //% "No active SIM cards are inserted"
                            return qsTrId("voicecall-la-no_active_sim")
                        } else if (!simFiltersHelper.anyActiveSimCanDial &&
                                   !simFiltersHelper.anyActiveSimCanReceive) {
                            //: Banner shown to the user when MDM has blocked all inserted SIM cards from dialing out or receiving calls
                            //: %1 is an operating system name without the OS suffix
                            //% "Outgoing and incoming calls are disabled by the %1 Device Manager"
                            return qsTrId("voicecall-la-outgoing_incoming_disabled_by_mdm")
                                .arg(aboutSettings.baseOperatingSystemName)
                        } else if (!simFiltersHelper.anyActiveSimCanDial) {
                            //: Banner shown to the user when MDM has blocked all inserted SIM cards from dialing out
                            //: %1 is an operating system name without the OS suffix
                            //% "Outgoing calls are disabled by the %1 Device Manager"
                            return qsTrId("voicecall-la-outgoing_disabled_by_mdm")
                                .arg(aboutSettings.baseOperatingSystemName)
                        } else if (!simFiltersHelper.anyActiveSimCanReceive) {
                            //: Banner shown to the user when MDM has blocked all inserted SIM cards from receiving calls
                            //: %1 is an operating system name without the OS suffix
                            //% "Incoming calls are disabled by the %1 Device Manager"
                            return qsTrId("voicecall-la-incoming_disabled_by_mdm")
                                .arg(aboutSettings.baseOperatingSystemName)
                        } else {
                            return ""
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: ongoingCall.height * ongoingCall.opacity
                    OngoingCallItem {
                        id: ongoingCall
                    }
                }

            }
        }

        model: [dialer, callHistoryView, peopleView]
        Component {
            id: dialer
            TabItem {
                flickable: dialerView.flickable
                DialerView {
                    id: dialerView
                    headerHeight: tabs.headerHeight
                    isCurrentItem: parent.isCurrentItem
                    Connections {
                        target: root
                        onReset: dialerView.reset()
                    }
                }
            }
        }
        Component {
            id: callHistoryView
            TabItem {
                allowDeletion: false
                flickable: _callHistoryView
                CallHistoryView {
                    id: _callHistoryView
                    header: Item { width: 1; height: tabs.headerHeight }
                    Connections {
                        target: root
                        onReset: _callHistoryView.reset()
                    }
                }
            }
        }
        Component {
            id: peopleView
            TabItem {
                flickable: _peopleView.contactView
                PeopleView {
                    id: _peopleView
                    allContactsModel: people
                    headerHeight: tabs.headerHeight

                    Connections {
                        target: root
                        onReset: _peopleView.reset()
                    }
                }
            }
        }
    }
}
