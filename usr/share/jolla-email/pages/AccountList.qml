/*
 * Copyright (c) 2013 – 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Email 0.1
import "utils.js" as Utils

Column {
    id: root

    width: parent.width

    Repeater {
        model: mailAccountListModel

        delegate: ListItem {
            id: accountItem
            property bool errorOccurred
            property string lastErrorText
            property bool updating

            width: root.width
            contentHeight: Theme.itemSizeExtraLarge
            menu: Component {
                ContextMenu {
                    id: contextMenu
                    MenuItem {
                        //: Update account
                        //% "Sync"
                        text: qsTrId("jolla-email-me-sync")
                        onClicked: emailAgent.synchronize(mailAccountId)
                    }
                }
            }

            Label {
                id: unreadCountLabel
                color: highlighted ? Theme.highlightColor : Theme.primaryColor
                text: unreadCount ? unreadCount : ""
                font.pixelSize: Theme.fontSizeLarge
                anchors {
                    left: accountItem.contentItem.left
                    leftMargin: Screen.sizeCategory >= Screen.Large ? Theme.horizontalPageMargin : 0
                    right: accountIcon.left
                    rightMargin: Theme.paddingLarge
                    verticalCenter: parent.verticalCenter
                }
                horizontalAlignment: Text.AlignRight
            }

            Image {
                id: accountIcon

                property string fixedIconPath: iconPath

                x: Screen.sizeCategory >= Screen.Large
                        ? 6 * Theme.paddingLarge
                        : 5 * Theme.paddingLarge
                width: Screen.sizeCategory >= Screen.Large
                        ? 90 * Theme.pixelRatio
                        : Screen.width / 5
                height: width
                sourceSize.width: width
                sourceSize.height: height
                anchors.verticalCenter: parent.verticalCenter
                source: fixedIconPath !== "" ? fixedIconPath : "image://theme/graphic-service-generic-mail"

                onStatusChanged: if (accountIcon.status == Image.Error) fixedIconPath = "image://theme/graphic-service-generic-mail"
            }

            Column {
                anchors {
                    left: accountIcon.right
                    leftMargin: Theme.paddingLarge
                    right: parent.right
                    rightMargin: Theme.horizontalPageMargin
                    verticalCenter: parent.verticalCenter
                    verticalCenterOffset: -Math.round(Theme.paddingSmall/2)
                }

                Label {
                    width: parent.width
                    text: displayName !== "" ? displayName : emailAddress
                    font.pixelSize: accountItem.errorOccurred ? Theme.fontSizeMedium : Theme.fontSizeLarge
                    color: unreadCountLabel.text !== "" ? (highlighted ? Theme.highlightColor : Theme.primaryColor)
                                                        : (highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor)
                    truncationMode: TruncationMode.Fade
                }

                Item {
                    width: parent.width
                    height: statusLabel.height

                    Icon {
                        id: errorIcon

                        y: (statusLabel.firstLineHeight - height) / 2

                        visible: accountItem.errorOccurred
                        source: "image://theme/icon-s-warning"
                    }

                    Label {
                        id: statusLabel

                        property real firstLineHeight

                        x: accountItem.errorOccurred ? errorIcon.width + Theme.paddingSmall : 0
                        width: parent.width - x
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                        wrapMode: Text.Wrap
                        text: {
                            // Cheating a bit as needsUpdate is always true but property changes are
                            // of our interest here.
                            var needsUpdate = Qt.application.active || accountItem.visible || app.refreshSyncTime || true
                            if (accountItem.updating) {
                                //: Updating account label
                                //% "Updating account..."
                                return qsTrId("jolla-email-la-updating_account")
                            } else if (accountItem.errorOccurred) {
                                return lastErrorText
                            } else if (needsUpdate) {
                                return hasPersistentConnection ? qsTrId("email-la_up_to_date") : Utils.lastSyncTime(lastSynchronized)
                            }
                            return ""
                        }

                        onLineLaidOut: {
                            if (line.number === 0) {
                                firstLineHeight = line.height
                            }
                        }
                    }
                }
            }
            onClicked: {
                app.pushAccountInbox(mailAccountId, false)
            }

            Connections {
                target: emailAgent

                onCurrentSynchronizingAccountIdChanged: {
                    if (emailAgent.currentSynchronizingAccountId === mailAccountId) {
                        accountItem.updating = true
                        accountItem.errorOccurred = false
                    } else {
                        accountItem.updating = false
                    }
                }

                onError: {
                    if (accountId === 0 || accountId === mailAccountId) {
                        accountItem.errorOccurred = true
                        accountItem.lastErrorText = Utils.syncErrorText(syncError)
                    }
                }
            }
        }
    }
}
