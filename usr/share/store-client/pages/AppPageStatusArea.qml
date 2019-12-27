import QtQuick 2.0
import Sailfish.Silica 1.0
import org.pycage.jollastore 1.0

Item {
    property ApplicationData app
    property int horizontalMargin: Theme.horizontalPageMargin

    width: parent.width
    height: Math.max(likeIcon.height, statusArea.height)

    Liker {
        id: liker

        store: jollaStore
        application: app.inStore ? app.application : ""
    }

    Image {
        id: likeIcon
        anchors {
            right: parent.right
            rightMargin: horizontalMargin
            verticalCenter: parent.verticalCenter
        }
        visible: app.inStore && jollaStore.isOnline && !liker.loading
        source: !visible ? ""
                         : ("image://theme/icon-m-like?" + (liker.isLiked || likeMouse.down
                                                            ? Theme.highlightColor
                                                            : Theme.primaryColor))

        MouseArea {
            id: likeMouse

            property bool down: pressed && containsMouse

            anchors.centerIn: parent
            width: likeIcon.width + 2 * Theme.paddingMedium
            height: likeIcon.height + 2 * Theme.paddingMedium
            enabled: !liker.busy

            onClicked: {
                if (liker.isLiked) {
                    liker.unlike(app.application)
                } else {
                    liker.like(app.application)
                }
            }
        }
    }

    Grid {
        id: statusArea
        anchors {
            left: parent.left
            leftMargin: horizontalMargin
            right: likeIcon.left
            rightMargin: Theme.paddingMedium
            verticalCenter: parent.verticalCenter
        }
        columns: Screen.sizeCategory > Screen.Medium ? 2 : 1
        columnSpacing: Theme.paddingLarge
        rowSpacing: Theme.paddingMedium

        Item {
            id: appStatusIndicator

            visible: app.inStore || app.state !== ApplicationState.Normal
            width: statusIcon.width + Theme.paddingSmall + statusLabel.width
            height: Math.max(statusIcon.height, statusLabel.height)

            Image {
                id: statusIcon
                anchors.verticalCenter: parent.verticalCenter
                visible: app.state === ApplicationState.Normal ||
                         app.state === ApplicationState.Installed ||
                         app.state === ApplicationState.Updatable

                source: app.state === ApplicationState.Installed
                        ? ("image://theme/icon-s-installed?" + Theme.highlightColor)
                        : app.state === ApplicationState.Updatable
                          ? ("image://theme/icon-s-update?" + Theme.highlightColor)
                          : app.androidApp
                            ? "image://theme/icon-s-android"
                            : ("image://theme/icon-s-sailfish?" + Theme.highlightColor)

            }

            BusyIndicator {
                running: appData.state === ApplicationState.Installing
                         || appData.state === ApplicationState.Updating
                         || appData.state === ApplicationState.Uninstalling
                anchors.centerIn: statusIcon
                size: BusyIndicatorSize.ExtraSmall
            }

            Label {
                id: statusLabel
                anchors {
                    left: statusIcon.right
                    leftMargin: Theme.paddingSmall
                    verticalCenter: parent.verticalCenter
                }
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.highlightColor
                truncationMode: TruncationMode.Fade
                text: app.state !== ApplicationState.Normal
                      ? packageHandler.applicationStateName(app.state,
                                                            app.progress)
                      : app.androidApp
                        //% "Android application"
                        ? qsTrId("jolla-store-la-android_app")
                        //% "Sailfish application"
                        : qsTrId("jolla-store-la-sailfish_app")
            }
        }

        Row {
            visible: app.inStore
            spacing: Theme.paddingLarge

            StatItem {
                source: "image://theme/icon-s-cloud-download?" + Theme.highlightColor
                text: app.downloads
            }
            StatItem {
                source: "image://theme/icon-s-like?" + Theme.highlightColor
                text: liker.loading ? app.likes : liker.likes
            }
            /*
              TODO: Uncomment when real data exists
            StatItem {
                source: "image://theme/icon-s-chat"
                text: "123"
            }
            */
        }
    }
}
