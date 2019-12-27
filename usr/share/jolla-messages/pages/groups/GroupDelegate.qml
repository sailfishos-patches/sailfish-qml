import QtQuick 2.6
import Sailfish.Silica 1.0
import org.nemomobile.contacts 1.0
import org.nemomobile.commhistory 1.0
import Sailfish.Contacts 1.0
import Sailfish.Messages 1.0

ListItem {
    id: delegate
    contentHeight: textColumn.height + Theme.paddingMedium + textColumn.y
    menu: contextMenuComponent
    property CommContactGroupModel groupModel

    property QtObject person: model.contactIds.length ? MessageUtils.peopleModel.personById(model.contactIds[0]) : null
    property string subscriberIdentity: model.subscriberIdentity || ''

    property string providerName: getProviderName()
    property bool hasIMAccount: _hasIMAccount()
    property date currentDateTime

    function getProviderName() {
        if (!model.lastEventGroup || !MessageUtils.telepathyAccounts.ready
                || MessageUtils.isSMS(model.lastEventGroup.localUid)) {
            return ""
        }

        return MessageUtils.accountDisplayName(person, model.lastEventGroup.localUid, model.lastEventGroup.remoteUids[0])
    }

    function _hasIMAccount() {
        var groups = model.groups
        for (var i = 0; i < groups.length; i++) {
            if (!MessageUtils.isSMS(groups[i].localUid))
                return true
        }
        return false
    }

    Column {
        id: textColumn
        anchors {
            top: parent.top
            topMargin: Theme.paddingSmall
            left: parent.left
            leftMargin: Theme.horizontalPageMargin
            right: parent.right
            rightMargin: Theme.horizontalPageMargin
        }

        Row {
            width: parent.width
            spacing: Theme.paddingMedium

            HighlightImage {
                id: groupIcon
                visible: model.groups[0].remoteUids.length > 1
                source: "image://theme/icon-s-group-chat"
                highlighted: delegate.highlighted
                anchors.verticalCenter: parent.verticalCenter
            }

            Label {
                id: name

                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                       - x
                       - (date.visible ? (date.width + parent.spacing) : 0)
                       - (warningIcon.visible ? (warningIcon.width + parent.spacing) : 0)
                       - (presence.visible ? (presence.width + parent.spacing) : 0)
                truncationMode: TruncationMode.Fade
                color: delegate.highlighted ? Theme.highlightColor : Theme.primaryColor
                text: (model.chatName !== undefined && model.chatName !== "") ? model.chatName :
                                                                                ((model.contactNames.length) ? model.contactNames.join(", ") : model.groups[0].remoteUids.join(", "))

            }

            ContactPresenceIndicator {
                id: presence

                anchors.verticalCenter: parent.verticalCenter
                visible: hasIMAccount
                presenceState: person ? person.globalPresenceState : Person.PresenceUnknown
            }

            HighlightImage {
                id: warningIcon

                visible: model.lastEventStatus === CommHistory.PermanentlyFailedStatus
                         || (model.lastEventStatus === CommHistory.TemporarilyFailedStatus && !channelManager.isPendingEvent(model.lastEventId))
                source: "image://theme/icon-s-warning"
                color: Theme.primaryColor
                anchors.verticalCenter: parent.verticalCenter
            }

            Label {
                id: date

                anchors.verticalCenter: parent.verticalCenter
                color: delegate.highlighted ? Theme.highlightColor : Theme.primaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
                visible: !warningIcon.visible
                text: {
                    // TODO ideally event status would be updated dynamically on the main messages page,
                    // but right now only the current conversation channel is accessible.
                    var label = mainWindow.eventStatusText(model.lastEventStatus, model.lastEventId)
                    if (!label) {
                        var today = new Date(currentDateTime).setHours(0, 0, 0, 0)
                        var messageDate = new Date(model.startTime).setHours(0, 0, 0, 0)
                        var daysDiff = (today - messageDate) / (24 * 60 * 60 * 1000)

                        if (daysDiff === 0) {
                            label = Format.formatDate(model.startTime, Formatter.DurationElapsed)
                        } else if (daysDiff < 7) {
                            label = Format.formatDate(model.startTime, Formatter.TimeValue)
                        } else if (daysDiff < 365) {
                            label = Format.formatDate(model.startTime, Formatter.DateMediumWithoutYear)
                        } else {
                            label = Format.formatDate(model.startTime, Formatter.DateMedium)
                        }

                        if (providerName) {
                            label = providerName + " \u2022 " + label
                        }
                    }
                    return label
                }
            }
        }

        Label {
            id: lastMessage
            width: parent.width

            text: {
                if (model.lastMessageText !== '') {
                    return model.lastMessageText
                } else if (model.lastEventType === CommHistory.MMSEvent) {
                    //% "Multimedia message"
                    return qsTrId("messages-ph-mms_empty_text")
                }
                return ''
            }

            textFormat: Text.PlainText
            font.pixelSize: Theme.fontSizeExtraSmall
            color: delegate.highlighted || model.unreadMessages > 0 ? Theme.secondaryHighlightColor : Theme.secondaryColor
            wrapMode: Text.Wrap
            maximumLineCount: 3
            onLineLaidOut: {
                if (line.number === 0 && model.lastEventIsDraft) {
                    var indent = Theme.iconSizeSmall + Theme.paddingSmall
                    line.x += indent
                    line.width -= indent
                }
            }

            Connections {
                target: groupModel.at(model.index)
                // forceLayout() deprecates doLayout() in Qt 5.9
                onLastEventChanged: lastMessage.doLayout()
            }

            HighlightImage {
                id: draftIcon

                visible: model.lastEventIsDraft
                highlighted: delegate.highlighted
                source: "image://theme/icon-s-edit"
                y: (fontMetrics.height - height) / 2
            }

            FontMetrics {
                id: fontMetrics
                font: lastMessage.font
            }

            GlassItem {
                visible: model.unreadMessages > 0
                color: Theme.highlightColor
                falloffRadius: 0.16
                radius: 0.15
                anchors {
                    left: parent.left
                    leftMargin: width / -2 - Theme.horizontalPageMargin
                    top: parent.top
                    topMargin: height / -2 + date.height / 2
                }
            }
        }
    }

    function remove() {
        remorseDelete(function() { model.contactGroup.deleteGroups() })
    }

    Component {
        id: contextMenuComponent

        ContextMenu {
            id: menu
            MenuItem {
                //% "Delete"
                text: qsTrId("messages-me-delete_conversation")
                onClicked: remove()
            }
        }
    }
}
