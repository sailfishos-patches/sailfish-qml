/****************************************************************************
**
** Copyright (C) 2014 Jolla Ltd.
** Contact: Martin Jones <martin.jones@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.5
import org.nemomobile.lipstick 0.1
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0
import Sailfish.Lipstick 1.0
import com.jolla.lipstick 0.1

Dialog {
    id: launcherFolder
    _clickablePageIndicators: false
    allowedOrientations: Lipstick.compositor.topmostWindowOrientation
    property var launcherPager
    property alias model: launcherGrid.model
    property bool selectIcon
    property Item iconSelector
    property int visibleRowCount: launcherGrid.rows-2

    function close(animate) {
        launcherGrid.setEditMode(false)
        reject()
    }

    Connections {
        target: Lipstick.compositor
        onDisplayOff: launcherFolder.close()
    }
    Connections {
        target: Lipstick.compositor.launcherLayer
        onActiveChanged: if (!Lipstick.compositor.launcherLayer.active) launcherFolder.close()
    }
    Connections {
        target: model
        onItemRemoved: if (model.itemCount === 0) launcherFolder.close()
    }
    Connections {
        target: launcherGrid.reorderItem
        onYChanged: {
            var maxContentY = launcherGrid.contentHeight - launcherGrid.height
            var globalY = launcherGrid.mapFromItem(launcherGrid.reorderItem, 0, 0).y
            if (globalY <= 0 && globalY >= -Theme.paddingLarge*2 && launcherGrid.contentY > 0) {
                launcherGrid.scroll(true)
            } else if (globalY + launcherGrid.cellHeight >= launcherGrid.height
                       && globalY + launcherGrid.cellHeight < launcherGrid.height + Theme.paddingLarge*2
                       && launcherGrid.contentY < maxContentY) {
                launcherGrid.scroll(false)
            } else {
                launcherGrid.stopScrolling()
            }
        }
    }

    MouseArea {
        property real pressPosY
        objectName: "LauncherFolder"
        anchors.fill: parent
        onPressAndHold: {
            if (Math.abs(mouseY - pressPosY) <= Theme.startDragDistance && !titleEditor.activeFocus && !selectIcon) {
                launcherGrid.setEditMode(true)
            }
        }
        onPressed: pressPosY = mouseY
        onClicked: {
            if (Math.abs(mouseY - pressPosY) <= Theme.startDragDistance) {
                if (titleEditor.activeFocus) {
                    titleEditor.focus = false
                } else if (selectIcon) {
                    selectIcon = false
                } else if (!launcherGrid.launcherEditMode) {
                    launcherFolder.close(true)
                }
                launcherGrid.setEditMode(false)
            }
        }

        Rectangle {
            id: header
            width: parent.width
            height: launcherIcon.height + Theme.paddingLarge
            gradient: Gradient {
                GradientStop { position: 0.0; color: Theme.rgba(Theme.primaryColor, 0.0) }
                GradientStop { position: 1.0; color: Theme.rgba(Theme.primaryColor, 0.15) }
            }
            opacity: 1 - footer.opacity

            Image {
                anchors.horizontalCenter: parent.horizontalCenter
                source: "image://theme/graphic-edge-swipe-handle-bottom"
            }

            MouseArea {
                id: iconHeader
                objectName: "LauncherFolder_icon"
                width: height
                height: parent.height
                x: Theme.paddingMedium
                FolderIconLoader {
                    id: launcherIcon
                    folder: model
                    anchors.centerIn: parent
                    pressed: iconHeader.pressed && iconHeader.containsMouse
                    Text {
                        font.pixelSize: Theme.fontSizeExtraLarge
                        font.family: Theme.fontFamilyHeading
                        color: Theme.lightPrimaryColor
                        text: model.itemCount
                        anchors.centerIn: parent
                        visible: launcherIcon.index < 16
                    }
                }
                onClicked: {
                    launcherGrid.setEditMode(false)
                    selectIcon = !selectIcon
                    if (!iconSelector) {
                        iconSelector = iconSelectorComponent.createObject(header.parent)
                    }
                    if (selectIcon) {
                        titleEditor.focus = false
                    }
                }
            }

            TextField {
                id: titleEditor
                anchors {
                    left: iconHeader.right
                    leftMargin: -Theme.paddingLarge
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                autoScrollEnabled: false
                font.pixelSize: Theme.fontSizeExtraLarge
                font.family: Theme.fontFamilyHeading
                text: model.title
                labelVisible: false
                background: null
                enabled: !selectIcon
                color: enabled ? Theme.primaryColor : Theme.highlightColor
                horizontalAlignment: Qt.AlignRight
                onActiveFocusChanged: {
                    if (!activeFocus) {
                        if (text.trim().length === 0) {
                            //% "Folder"
                            text = qsTrId("lipstick-jolla-home-folder")
                        }
                        launcherGrid.model.title = text
                    } else {
                        launcherGrid.setEditMode(false)
                        cursorPosition = text.length
                    }
                }

                EnterKey.onClicked: focus = false
                EnterKey.iconSource: "image://theme/icon-m-enter-close"
            }
            Label {
                anchors {
                    right: titleEditor.right
                    rightMargin: Theme.horizontalPageMargin
                    bottom: parent.bottom
                    bottomMargin: Theme.paddingMedium
                }
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.highlightColor
                text: titleEditor.activeFocus ?
                          //% "Enter folder name"
                          qsTrId("lipstick-jolla-home-enter-folder-name") :
                          //% "Select folder shape"
                          qsTrId("lipstick-jolla-home-select-folder-shape")
                visible: titleEditor.activeFocus || selectIcon
            }
        }

        Item {
            // Use a clipper item to clip slightly outside the GridView area
            anchors.top: header.bottom
            width: parent.width
            height: launcherGrid.height
            clip: launcherGrid.reorderItem ? false : true

            LauncherGrid {
                id: launcherGrid
                function scroll(up) {
                    contentYAnimation.to = up ? originY : originY + contentHeight - height
                    contentYAnimation.duration = Math.abs(contentY - contentYAnimation.to)
                    contentYAnimation.start()
                }

                function stopScrolling() {
                    contentYAnimation.stop()
                }

                gridManager.dragContainer: launcherFolder

                NumberAnimation {
                    id: contentYAnimation
                    target: launcherGrid
                    property: "contentY"
                    easing.type: Easing.InOutQuad
                }

                MouseArea {
                    property var pressPos
                    objectName: "LauncherFolder_editMode"
                    anchors.fill: parent
                    z: -1
                    onPressAndHold: launcherGrid.setEditMode(true)
                    onPressed: pressPos = mouseY
                    onClicked: {
                        if (Math.abs(mouseY - pressPos) <= Theme.startDragDistance) {
                            if (titleEditor.activeFocus) {
                                titleEditor.focus = false
                            } else if (selectIcon) {
                                selectIcon = false
                            } else if (!launcherGrid.launcherEditMode) {
                                launcherFolder.close(true)
                            }
                            launcherGrid.setEditMode(false)
                        }
                    }
                }

                VerticalScrollDecorator { anchors.rightMargin: -launcherGrid.x }

                y: Theme.fontSizeExtraSmall/2
                height: launcherFolder.height - header.height
                cacheBuffer: height
                displayMarginBeginning: Theme.fontSizeExtraSmall/2
                displayMarginEnd: Theme.fontSizeExtraSmall/2
                enabled: !titleEditor.activeFocus && !selectIcon
                Behavior on opacity { FadeAnimation { duration: 300 } }
                opacity: enabled ? 1.0 : (selectIcon ? 0.0 : Theme.opacityLow)
                footer: Item { width: 1; height: Theme.paddingSmall}
            }
        }

        Rectangle {
            id: footer
            property bool draggedIntoFooter: {
                var item = launcherGrid.reorderItem
                if (item) {
                    // The odd launcherGrid.reorderItem.y line below is to force revaluation of this binding
                    launcherGrid.reorderItem.y
                    var itemY = header.mapFromItem(item, 0, 0).y
                    if (itemY < header.height / 2)
                        return true
                }
                return false
            }
            property bool shown: (launcherGrid.launcherEditMode && launcherGrid.reorderItem ||
                                  model.itemCount > launcherGrid.columns * visibleRowCount) && !selectIcon
            height: header.height
            width: parent.width
            y: 0
            opacity: launcherGrid.launcherEditMode && launcherGrid.reorderItem ?
                         (draggedIntoFooter ? 1.0 : 0.8) : 0.0
            Behavior on opacity { FadeAnimation {} }
            color: Theme.highlightDimmerColor
            gradient: Gradient {
                GradientStop { position: 0.0; color: Theme.rgba(Theme.primaryColor, Theme.highlightBackgroundOpacity) }
                GradientStop { position: 1.0; color: Theme.rgba(Theme.primaryColor, 0.0) }
            }
        }
        Label {
            x: Theme.horizontalPageMargin
            width: parent.width - 2*x
            anchors.verticalCenter: footer.verticalCenter
            color: Theme.highlightColor
            opacity: launcherGrid.launcherEditMode && launcherGrid.reorderItem ? 1.0 : 0.0
            Behavior on opacity { FadeAnimation {} }
            horizontalAlignment: Qt.AlignHCenter
            wrapMode: Text.Wrap
            //% "Drop icon here to remove it from folder"
            text: qsTrId("lipstick-jolla-home-drop-icon-here-to-remove")
        }
    }

    Component {
        id: iconSelectorComponent
        SilicaFlickable {
            anchors {
                top: header.bottom
                topMargin: Theme.fontSizeExtraSmall/2
                horizontalCenter: parent.horizontalCenter
            }
            width: folderIconGrid.width
            height: launcherFolder.height - header.height
            contentHeight: folderIconGrid.height
            opacity: selectIcon ? 1.0 : 0.0
            Behavior on opacity { FadeAnimation { duration: 300 } }
            enabled: selectIcon
            onEnabledChanged: if (enabled) contentY = 0
            clip: true

            VerticalScrollDecorator {}

            MouseArea {
                objectName: "LauncherFolder_iconSelector"
                width: parent.width
                height: folderIconGrid.height
                onClicked: selectIcon = false

                Grid {
                    id: folderIconGrid
                    columns: Math.floor(launcherGrid.width/launcherGrid.cellWidth)
                    Repeater {
                        model: 20
                        delegate: MouseArea {
                            id: folderIcon
                            width: launcherGrid.cellWidth
                            height: launcherGrid.cellHeight
                            FolderIconLoader {
                                id: folderLauncherIcon
                                anchors {
                                    centerIn: parent
                                    verticalCenterOffset: Math.round(-Theme.fontSizeExtraSmall/2)
                                }
                                folder: launcherFolder.model
                                index: model.index
                                icon: "image://theme/icon-launcher-folder-" + (index >= 9 ? (index+1) : "0" + (index+1))
                                pressed: folderIcon.pressed && folderIcon.containsMouse
                                opacity: icon.indexOf(launcherFolder.model.iconId) !== -1 ? Theme.opacityFaint : 1.0
                            }
                            Image {
                                anchors.centerIn: folderLauncherIcon
                                source: folderLauncherIcon.opacity !== 1.0 ? "image://theme/icon-s-installed" : ""
                            }
                            onClicked: {
                                launcherGrid.model.iconId = "icon-launcher-folder-" + (index >= 9 ? (index+1) : "0" + (index+1))
                                selectIcon = false
                            }
                        }
                    }
                }
            }
        }
    }
}
