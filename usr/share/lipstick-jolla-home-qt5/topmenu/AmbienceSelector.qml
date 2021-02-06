/****************************************************************************
**
** Copyright (C) 2018 - 2019 Jolla Ltd.
** Copyright (C) 2020 Open Mobile Platform LLC.
**
****************************************************************************/

import QtQuick 2.5
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0
import Sailfish.Ambience 1.0
import Sailfish.Gallery 1.0
import Nemo.DBus 2.0
import Nemo.Thumbnailer 1.0
import org.nemomobile.notifications 1.0 as SystemNotifications
import org.nemomobile.configuration 1.0
import org.nemomobile.lipstick 0.1
import org.nemomobile.devicelock 1.0
import com.jolla.lipstick 0.1

Item {
    id: root

    property int itemSize
    property int viewHeight
    property real verticalOffset
    property bool expanded

    function resetView() {
        ambienceList.positionViewAtBeginning()
    }

    width: parent.width
    height: ambienceList.height
    visible: ambiencesEnabled.value
    clip: ambienceList.y < 0

    Timer {
        id: ambiencePreviewTimer
        interval: 200
        onTriggered: ambiencePreviewNotification.publish()
    }

    SystemNotifications.Notification {
        id: ambiencePreviewNotification
        category: "x-jolla.ambience.preview"
    }

    ConfigurationValue {
        id: ambiencesEnabled
        key: "/desktop/lipstick-jolla-home/topmenu_ambiences_enabled"
        defaultValue: true
    }

    DBusInterface {
        id: settingsApp

        service: "com.jolla.settings"
        path: "/com/jolla/settings/ui"
        iface: "com.jolla.settings.ui"
    }

    SilicaListView {
        id: ambienceList

        width: parent.width
        height: root.viewHeight
        y: Math.min(0, -height - parent.y + root.verticalOffset)
        orientation: ListView.Horizontal
        clip: Lipstick.compositor.topMenuLayer.window.orientation === Qt.LandscapeOrientation ||
              Lipstick.compositor.topMenuLayer.window.orientation === Qt.InvertedLandscapeOrientation ||
              Screen.sizeCategory > Screen.Medium

        add: Transition {
            id: addTransition

            SequentialAnimation {
                PropertyAction { property: "z"; value: -1 }
                NumberAnimation { property: "x"; from: root.itemSize * (addTransition.ViewTransition.targetIndexes[0] - 1); duration: 500; easing.type: Easing.InOutQuad }
                PropertyAction { property: "z"; value: 0 }
            }
        }

        displaced: Transition {
            NumberAnimation { property: "x"; duration: 500; easing.type: Easing.InOutQuad }
        }

        model: AmbienceInstallModel {
            source: AmbienceModel {
                id: ambienceModel
            }

            onAmbienceInstalling: {
                ambiencePreviewNotification.summary = displayName
                ambiencePreviewNotification.body = coverImage
                // Give some time for the TOH dialog to fade out
                ambiencePreviewTimer.restart()
            }

            onAmbienceInstalled: ambienceModel.makeCurrent(index)
        }

        delegate: ListItem {
            id: thumbnailBackground

            readonly property bool dimmed: ambienceList.__silica_contextmenu_instance
                                           && ambienceList.__silica_contextmenu_instance.active
                                           && ambienceList.__silica_contextmenu_instance.parent != thumbnailBackground

            width: root.itemSize
            contentHeight: width
            highlightedColor: Theme.rgba(highlightBackgroundColor || Theme.highlightBackgroundColor, Theme.highlightBackgroundOpacity)
            openMenuOnPressAndHold: Desktop.deviceLockState === DeviceLock.Unlocked

            onClicked: {
                ambienceModel.makeCurrent(index)
                Lipstick.compositor.topMenuLayer.hide()
            }

            menu: Component {
                ContextMenu {
                    // Ensure the flickable contentY doesn't scroll upwards if the opening of the menu expands
                    // the flickable contentHeight beyond the current top window dimensions.
                    container: Lipstick.compositor.topMenuLayer.topMenu.parent

                    MenuItem {
                        id: addToFavorites
                        //% "Add to favorites"
                        text: qsTrId("lipstick-jolla-home-la-topmenu_add_favorite")
                        onDelayedClick: ambienceModel.setProperty(model.index, "favorite", true)
                    }

                    MenuItem {
                        id: removeFromFavorites
                        //% "Remove from favorites"
                        text: qsTrId("lipstick-jolla-home-la-topmenu_remove_favorite")
                        onDelayedClick: ambienceModel.setProperty(model.index, "favorite", false)
                    }

                    MenuItem {
                        //: Show the relevant settings options for this.
                        //% "Go to settings"
                        text: qsTrId("lipstick-jolla-home-la-topmenu_go_to_settings")
                        onClicked: settingsApp.call('showAmbienceSettings', [model.contentId])
                    }

                    onActiveChanged: {
                        if (active) {
                            addToFavorites.visible = !model.favorite
                            removeFromFavorites.visible = model.favorite
                        }
                    }
                }
            }

            Thumbnail {
                z: -1

                width: root.itemSize
                height: width
                sourceSize { width: root.itemSize; height: width }
                source: wallpaperUrl != undefined ? wallpaperUrl : ""

                onStatusChanged: {
                    if (status == Thumbnail.Error) {
                        console.log("Thumbnail error for:", source)
                    }
                }
            }

            Rectangle {
                z: -1
                anchors.fill: parent
                color: thumbnailBackground.dimmed ? Theme.overlayBackgroundColor : Qt.darker(highlightedColor)
                opacity: color == Theme.overlayBackgroundColor ? Theme.opacityHigh : Theme.opacityLow

                Behavior on opacity { FadeAnimation {} }
            }

            Image {
                anchors {
                    right: parent.right
                    rightMargin: Theme.paddingSmall
                    top: parent.top
                    topMargin: Theme.paddingSmall
                }
                visible: model.favorite
                source: "image://theme/icon-s-favorite?" + (thumbnailBackground.highlighted ? Theme.highlightColor : model.primaryColor)

                opacity: thumbnailBackground.dimmed ? Theme.highlightBackgroundOpacity : 1.0
            }

            Rectangle {
                anchors {
                    fill: ambienceLabel
                    margins: -ambienceLabel.anchors.margins
                }
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.5; color: model.colorScheme === Theme.LightOnDark ? "black" : "white" }
                }
            }

            Label {
                id: ambienceLabel
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    margins: Theme.paddingSmall
                }
                color: thumbnailBackground.highlighted ? Theme.highlightColor : model.primaryColor
                horizontalAlignment: implicitWidth > width ? Text.AlignLeft : Text.AlignHCenter
                truncationMode: TruncationMode.Fade
                font.pixelSize: Theme.fontSizeSmall
                opacity: thumbnailBackground.dimmed ? Theme.highlightBackgroundOpacity : 1.0
                text: model.displayName
            }
        }

        states: State {
            name: "expanded"
            when: root.expanded
            PropertyChanges { target: ambienceList; y: 0 }
        }

        transitions: Transition {
            to: "expanded"
            NumberAnimation { properties: "y"; duration: 200 }
        }
    }
}
