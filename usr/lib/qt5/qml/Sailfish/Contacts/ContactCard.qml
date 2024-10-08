/*
 * Copyright (c) 2013 - 2019 Jolla Pty Ltd.
 * Copyright (c) 2019 - 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
*/

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0
import Sailfish.Telephony 1.0
import Sailfish.Contacts 1.0 as SailfishContacts
import Sailfish.AccessControl 1.0
import QOfono 0.2
import org.nemomobile.contacts 1.0
import Nemo.DBus 2.0
import "contactcard/contactcardmodelfactory.js" as ModelFactory
import "contactcard"

/*!
  \inqmlmodule Sailfish.Contacts
*/
SilicaFlickable {
    id: root

    property var contact
    property string activeDetail
    readonly property bool actionPermitted: AccessControl.hasGroup(AccessControl.RealUid, "sailfish-phone")
                                         || AccessControl.hasGroup(AccessControl.RealUid, "sailfish-messages")
    property bool hidePhoneActions: cellular1Status.modemPath.length === 0 && cellular2Status.modemPath.length === 0 || !actionPermitted
    property bool disablePhoneActions: !cellular1Status.registered && !cellular2Status.registered

    /*!
      \internal
    */
    property QtObject _messagesInterface
    /*!
      \internal
    */
    property date _today: new Date()

    function refreshDetails() {
        SailfishContacts.ContactsUtil.init()
        ModelFactory.init(SailfishContacts.ContactsUtil)
        ModelFactory.getContactCardDetailsModel(details.model, contact)
    }

    /*!
      \internal
    */
    function _asyncRefresh() {
        if (contact.complete) {
            contact.completeChanged.disconnect(_asyncRefresh)
            refreshDetails()
        }
    }

    function startPhoneCall(number, modemPath) {
        if (modemPath !== undefined && modemPath !== "") {
            voicecall.dialViaModem(modemPath, number)
        } else {
            voicecall.dial(number)
        }
    }

    function startSms(number) {
        messagesInterface().startSMS(number)
    }

    function startInstantMessage(localUid, remoteUid) {
        messagesInterface().startConversation(localUid, remoteUid)
    }

    function messagesInterface() {
        if (!_messagesInterface) {
            _messagesInterface = Qt.createQmlObject('import "common"; MessagesInterface { }', root)
            if (!_messagesInterface)
                console.log("ContactCardPage: Failed creating MessagesInterface instance")
        }
        return _messagesInterface
    }

    /*!
      \internal
    */
    function _scrollToFit(item, newItemHeight) {
        var newContentY = Math.max(item.mapToItem(root.contentItem, 0, newItemHeight).y - root.height,
                                   root.contentY)
        repositionAnimation.to = newContentY
        repositionAnimation.start()
    }

    function appendIfExists(query, key, value) {
        if (value != "") {
            return query + "&"+ key + "=" + encodeURIComponent(value)
        } else {
            return query
        }
    }

    function openAddress(street, city, region, zipcode, country) {
        var content = [street, city, region, zipcode, country]
        content = content.filter(function(item) { return item != "" } )

        // q= is android extension, containing a search query. try to combine all the details there
        var geoUri = "geo:0,0?q=" + encodeURIComponent(content.join(","))

        // these are sailfish extension, having the fields separately
        geoUri = appendIfExists(geoUri, "street", street)
        geoUri = appendIfExists(geoUri, "city", city)
        geoUri = appendIfExists(geoUri, "region", region)
        geoUri = appendIfExists(geoUri, "zipcode", zipcode)
        geoUri = appendIfExists(geoUri, "country", country)

        Qt.openUrlExternally(geoUri)
    }

    onContactChanged: {
        if (contact) {
            if (contact.complete) {
                refreshDetails()
            } else {
                contact.completeChanged.connect(_asyncRefresh)
            }
        } else {
            details.model.clear()
        }
    }

    Connections {
        target: contact || null
        onDataChanged: refreshDetails()
    }

    width: parent ? parent.width : Screen.width
    height: parent ? parent.height : Screen.height
    contentHeight: details.y + details.height

    Timer {
        id: repositionTimer

        property var delegate

        interval: 100   // wait briefly for delegate height to be corrected when expanded
        onTriggered: {
            root._scrollToFit(delegate, Math.min(Screen.height, delegate.height))
        }
    }

    NumberAnimation {
        id: repositionAnimation
        target: root
        property: "contentY"
        easing.type: Easing.InOutQuad
        duration: 300
    }

    ContactHeader {
        id: header

        contact: root.contact
        simManager: _simManager
    }

    ListView {
        id: details
        interactive: false

        width: parent.width
        y: header.height + Theme.paddingLarge

        onContentHeightChanged: height = contentHeight

        // This list view should not move to accommodate the context menu
        property int __silica_hidden_flickable

        model: ListModel {}

        delegate: Loader {
            id: detailDelegateLoader

            width: parent.width
            sourceComponent: detailsType == "activity" ? activityDelegateComponent : detailDelegateComponent

            Component {
                id: detailDelegateComponent

                ContactDetailDelegate {
                    id: detailDelegate

                    width: details.width
                    previousDetailType: model.index > 0 ? details.model.get(model.index - 1).detailsType : ""
                    detailType: detailsType
                    detailIndex: detailsIndex
                    detailValue: detailsValue
                    detailData: detailsData
                    detailMetadata: detailsLabel
                    constituentId: model.detailsOriginId || 0

                    hidePhoneActions: root.hidePhoneActions
                    disablePhoneActions: root.disablePhoneActions

                    onCallClicked: {
                        console.log("Call number: " + number + ", connection: " + connection + ", modem: " + modemPath)
                        root.startPhoneCall(number, modemPath)
                    }

                    onSmsClicked: {
                        console.log("SMS number: " + number + ", connection: " + connection)
                        root.startSms(number)
                    }

                    onEmailClicked: {
                        Qt.openUrlExternally("mailto:" + email)
                    }

                    onImClicked: {
                        console.log("IMAddress: " + localUid + ":" + remoteUid)
                        root.startInstantMessage(localUid, remoteUid)
                    }

                    onAddressClicked: {
                        console.log("Address: " + address)
                        root.openAddress(addressParts["street"], addressParts["city"],
                                         addressParts["region"], addressParts["zipcode"],
                                         addressParts["country"])
                    }

                    onCopyToClipboardClicked: {
                        console.log("Copy to clipboard: " + detailValue)
                        Clipboard.text = detailValue
                    }

                    onWebsiteClicked: {
                        var schemeSeparatorIndex =  url.indexOf(':')
                        if (schemeSeparatorIndex <= 0 || schemeSeparatorIndex > 'https'.length) {
                            // Assume http
                            url = 'http://' + url
                        }
                        console.log("Website: " + url)
                        Qt.openUrlExternally(url)
                    }

                    onDateClicked: {
                        // Rather than showing the contact's actual birth or anniversary date in the calendar,
                        // show the next occurrence of the anniversary of the recorded date
                        var now = new Date()
                        var nextDate = new Date(now.getFullYear(), date.getMonth(), date.getDate())
                        if (new Date(now.getFullYear(), now.getMonth(), now.getDate()) > nextDate) {
                            nextDate.setFullYear(nextDate.getFullYear() + 1)
                        }
                        var formatted = Qt.formatDate(nextDate, Qt.ISODate)
                        console.log("Date: " + formatted)
                        calendarInterface.showDate(formatted)
                    }

                    onContentResized: {
                        root._scrollToFit(item, newItemHeight)
                    }
                }
            }

            Component {
                id: activityDelegateComponent

                MouseArea {
                    id: activityDelegate
                    width: details.width
                    height: activityHeader.y + activityHeader.height + expandingContainer.height

                    SectionHeader {
                        id: activityHeader
                        //% "Activity"
                        text:  qsTrId("components_contacts-la-activity")
                        font.pixelSize: Theme.fontSizeMedium
                        y: Theme.paddingMedium
                        opacity: loader.item && loader.item.activityCount > 0 ? 1 : 0
                        Behavior on opacity { FadeAnimator {} }
                    }

                    Item {
                        id: expandingContainer
                        anchors.top: activityHeader.bottom
                        width: activityDelegate.width
                        height: loader.item ? loader.item.height : Theme.itemSizeMedium

                        Loader {
                            id: loader
                            sourceComponent: activityListComponent
                            anchors.fill: parent
                        }
                        BusyIndicator {
                            anchors.centerIn: parent
                            running: loader.status != Loader.Ready
                            visible: running
                        }
                    }

                    Component {
                        id: activityListComponent

                        Item {
                            readonly property int activityCount: activityList.count

                            width: parent.width
                            height: activityList.height + Math.max(showMore.height, seeAll.height)

                            ContactActivityList {
                                id: activityList

                                modelFactory: ModelFactory
                                contact: root.contact
                                reduced: true
                                reducedLimit: 3
                                limit: 15
                                hidePhoneActions: root.hidePhoneActions
                                today: root._today
                                simManager: _simManager

                                opacity: count === 0 ? 0 : 1
                                Behavior on opacity { FadeAnimation {} }

                                onStartPhoneCall: root.startPhoneCall(number, modemPath)
                                onStartSms: root.startSms(number)
                                onStartInstantMessage: root.startInstantMessage(localUid, remoteUid)
                            }

                            BackgroundItem {
                                id: showMore

                                anchors.top: activityList.bottom
                                height: visible ? Theme.itemSizeExtraSmall : 0
                                visible: activityList.ready && activityList.reduced && activityList.count > activityList.reducedLimit
                                opacity: activityList.opacity

                                onClicked: {
                                    activityList.reduced = false
                                    repositionTimer.delegate = detailDelegateLoader
                                    repositionTimer.start()
                                }

                                ShowMoreButton {
                                    id: showMoreButton

                                    x: Theme.horizontalPageMargin
                                    y: showMore.height/2 - height/2
                                    enabled: false
                                    highlighted: showMore.highlighted
                                }
                            }

                            BackgroundItem {
                                id: seeAll

                                anchors.top: activityList.bottom
                                height: visible ? Theme.itemSizeSmall : 0
                                visible: activityList.ready && !activityList.reduced && activityList.hasMore

                                Image {
                                    id: rightIcon

                                    anchors {
                                        right: parent.right
                                        rightMargin: Theme.paddingMedium
                                        verticalCenter: parent.verticalCenter
                                    }
                                    source: "image://theme/icon-m-right?" + (seeAll.down ? Theme.highlightColor : Theme.primaryColor)
                                }
                                Label {
                                    anchors {
                                        right: rightIcon.left
                                        rightMargin: Theme.paddingMedium
                                        verticalCenter: parent.verticalCenter
                                    }
                                    //% "See all activity"
                                    text: qsTrId("components_contacts-la-see_all_activity")
                                    color: seeAll.down ? Theme.highlightColor : Theme.primaryColor
                                }

                                onClicked: {
                                    pageStack.animatorPush(activityPageComponent)
                                }

                                Component {
                                    id: activityPageComponent

                                    ContactActivityPage {
                                        hidePhoneActions: root.hidePhoneActions
                                        contact: root.contact
                                        modelFactory: ModelFactory
                                        simManager: _simManager

                                        onStartPhoneCall: root.startPhoneCall(number, modemPath)
                                        onStartSms: root.startSms(number)
                                        onStartInstantMessage: root.startInstantMessage(localUid, remoteUid)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    DBusInterface {
        id: voicecall

        service: "com.jolla.voicecall.ui"
        path: "/"
        iface: "com.jolla.voicecall.ui"

        function dial(number) {
            call('dial', number)
        }

        function dialViaModem(modemPath, number) {
            call('dialViaModem', [ modemPath, number ])
        }
    }
    DBusInterface {
        id: calendarInterface

        service: "com.jolla.calendar.ui"
        path: "/com/jolla/calendar/ui"
        iface: "com.jolla.calendar.ui"

        function showDate(date) {
            call('viewDate', date)
        }
    }

    OfonoManager {
        id: ofonoManager
    }

    OfonoNetworkRegistration {
        id: cellular1Status

        property bool disabled: status == ""
        property bool registered: status == "registered" || status == "roaming"

        modemPath: ofonoManager.modems[0] || ""
    }

    OfonoNetworkRegistration {
        id: cellular2Status

        property bool disabled: status == ""
        property bool registered: status == "registered" || status == "roaming"

        modemPath: ofonoManager.modems[1] || ""
    }

    SimManager {
        id: _simManager
    }

    VerticalScrollDecorator {}
}
