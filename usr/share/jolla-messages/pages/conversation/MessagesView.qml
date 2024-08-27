import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0
import Sailfish.Contacts 1.0
import Sailfish.Messages 1.0
import org.nemomobile.commhistory 1.0
import Nemo.Time 1.0

SilicaListView {
    id: messagesView

    verticalLayoutDirection: ListView.BottomToTop
    // Necessary to avoid resetting focus every time a row is added, which breaks text input
    currentIndex: -1
    _quickScrollItem.directionsEnabled: QuickScrollDirection.Down

    function formatDate(date) {
        var today = new Date
        if (date.getDate() == today.getDate()
                && date.getMonth() == today.getMonth()
                && date.getFullYear() == today.getFullYear()) {
            //% "Today"
            return qsTrId("messages-la-today")
        } else {
            return Format.formatDate(date, Formatter.TimepointSectionRelative)
        }
    }

    BackgroundRectangle {
        width: parent.width
        height: stickyHeader.height
        z: 1

        SectionHeader {
            id: stickyHeader
            property var date: undefined
            text: date !== undefined && Qt.application.active ? messagesView.formatDate(date) : ""
            horizontalAlignment: Text.AlignHCenter
            color: Theme.secondaryColor
        }
    }

    delegate: Item {
        id: wrapper

        property bool isSMS: MessageUtils.isSMS(model.localUid)
        // This would normally be previousSection, but our model's order is inverted.
        property bool sectionBoundary: (ListView.nextSection != "" && ListView.nextSection !== ListView.section)
                                        || model.index === messagesView.count - 1
        property Item section
        property var previousEvent: model.index === 0 ? null : messagesView.model.event(model.index - 1)
        property var nextEvent: model.index === (messagesView.count - 1) ? null : messagesView.model.event(model.index + 1)

        // The initial state of an outgoing message is TemporarilyFailed, but we don't want to show that while
        // trying to send. Report this message's status as Sending if the message is currently pending in the channel
        property int eventStatus: {
            if (model.status == CommHistory.TemporarilyFailedStatus &&
                conversation.message.eventIsPending(model.localUid, model.remoteUid, model.eventId)) {
                return CommHistory.SendingStatus
            }
            return model.status
        }

        property bool lastVisibleItem: messagesView.contentY > y && messagesView.contentY < y + height
        onLastVisibleItemChanged: if (lastVisibleItem) stickyHeader.date = model.startTime

        height: loader.y + loader.height
        width: parent.width

        ListView.onRemove: loader.item.animateRemoval(wrapper)

        Loader {
            id: loader
            y: section ? section.y + section.height : 0
            width: parent.width
            sourceComponent: isSMS ? smsDelegate : imDelegate
        }

        onSectionBoundaryChanged: {
            if (sectionBoundary) {
                var properties = {
                    'modelData': model,
                    'section': ListView.section,
                    'nextSection': ListView.nextSection
                }
                section = sectionHeader.createObject(wrapper, properties)
            } else {
                section.destroy()
                section = null
            }
        }

        Component {
            id: smsDelegate

            SMSMessageDelegate {
                modelData: model
                eventStatus: wrapper.eventStatus
                currentDateTime: wallClock.time
                groupFirst: !previousEvent || previousEvent.direction !== model.direction || previousEvent.dateAndAccountGrouping !== model.dateAndAccountGrouping
                groupLast: !nextEvent || nextEvent.direction !== model.direction || nextEvent.dateAndAccountGrouping !== model.dateAndAccountGrouping
            }
        }

        Component {
            id: imDelegate

            IMMessageDelegate {
                modelData: model
                eventStatus: wrapper.eventStatus
            }
        }
    }

    section.property: "dateAndAccountGrouping"

    Component {
        id: sectionHeader

        Column {
            id: header

            property QtObject modelData
            property string section
            property string nextSection
            property bool accountsMatch: nextSection && section.substring(11) === nextSection.substring(11)
            property bool datesMatch: nextSection && section.substring(0, 10) === nextSection.substring(0, 10)
            property bool reparent: messagesView.contentY > header.parent.y - height

            width: messagesView.width

            Item {
                id: sectionDelegate

                width: parent.width
                height: dateSection.height
                visible: !datesMatch

                BackgroundRectangle {
                    width: parent.width
                    height: dateSection.height
                    parent: reparent ?  messagesView : sectionDelegate
                    y: reparent ? Math.max(0, header.parent.y - messagesView.contentY) : 0
                    z: messagesView.contentHeight - Math.abs(header.parent.y)

                    SectionHeader {
                        id: dateSection
                        horizontalAlignment: Text.AlignHCenter
                        color: Theme.secondaryColor
                        text: (modelData && Qt.application.active) ? messagesView.formatDate(modelData.startTime) : ""
                    }
                }
            }

            SectionHeader {
                id: accountNameHeader
                visible: !accountsMatch
                horizontalAlignment: Text.AlignHCenter
                color: Theme.secondaryColor
                text: !modelData ? "" : MessageUtils.accountDisplayName(conversation.people[0], modelData.localUid, modelData.remoteUid)

                ContactPresenceIndicator {
                    x: header.width / 2 + accountNameHeader.implicitWidth / 2 - accountNameHeader.x + Theme.paddingMedium
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !header.parent.isSMS && conversation.people.length === 1
                    presenceState: modelData ? MessageUtils.presenceForPersonAccount(conversation.people[0],
                                                                                     modelData.localUid,
                                                                                     modelData.remoteUid) : 0
                }
            }
        }
    }

    function remove(contentItem) {
        contentItem.remorseDelete(
            function() {
                messagesView.model.deleteEvent(contentItem.modelData.eventId)
            })
    }

    function copy(contentItem) {
        Clipboard.text = contentItem.modelData.freeText || contentItem.modelData.subject
    }

    Component {
        id: messageContextMenu

        ContextMenu {
            id: menu

            // Only evaluated on open to avoid value changes while menu is active
            onActiveChanged: {
                retryItem.visible = (menu.parent && menu.parent.canRetry)
                var modelData = menu.parent.modelData
                var eventStatus = menu.parent ? menu.parent.eventStatus : CommHistory.UnknownStatus
                cancelItem.visible = modelData.eventType === CommHistory.MMSEvent && 
                        (eventStatus === CommHistory.DownloadingStatus ||
                         eventStatus === CommHistory.WaitingStatus ||
                         eventStatus === CommHistory.SendingStatus)
            }

            width: parent ? parent.width : Screen.width

            MenuItem {
                id: retryItem
                //% "Retry"
                text: qsTrId("messages-me-retry_message")
                onClicked: conversation.message.retryEvent(menu.parent.modelData)
            }
            MenuItem {
                id: cancelItem
                //% "Cancel"
                text: qsTrId("messages-me-cancel")
                onClicked: conversation.message.cancelEvent(menu.parent.modelData)
            }
            MenuItem {
                visible: menu.parent && menu.parent.hasText
                text: menu.parent && menu.parent.hasAttachments ?
                        //: Shown when message has attachments, and only the text of the message will be copied.
                        //% "Copy text"
                        qsTrId("messages-me-copy_message_text") :
                        //% "Copy"
                        qsTrId("messages-me-copy_message")
                onClicked: copy(menu.parent)
            }
            MenuItem {
                //% "Delete"
                text: qsTrId("messages-me-delete_message")
                onClicked: remove(menu.parent)
            }
        }
    }

    WallClock {
        id: wallClock
        enabled: Qt.application.active
        updateFrequency: WallClock.Minute
    }

    VerticalScrollDecorator {}
}

