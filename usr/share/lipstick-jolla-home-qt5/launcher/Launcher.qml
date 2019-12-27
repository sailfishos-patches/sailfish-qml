/*
 * Copyright (c) 2013 Jolla Ltd.
 * Copyright (c) 2019 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.1
import org.nemomobile.lipstick 0.1
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0 as SilicaPrivate
import Sailfish.Policy 1.0
import org.nemomobile.configuration 1.0
import Sailfish.Lipstick 1.0
import org.nemomobile.configuration 1.0
import com.jolla.lipstick 0.1

SilicaListView {
    id: launcherPager

    ConfigurationGroup {
        id: launcherSettings
        path: "/apps/lipstick-jolla-home-qt5/launcher"
        property bool freeScroll: true
        property bool useScroll: true
        onFreeScrollChanged: launcher.manageDummyPages()
    }

    property bool launcherActive: Lipstick.compositor.launcherLayer.active
    onLauncherActiveChanged: if (!launcherActive) { resetPosition(400) }

    property bool editMode: launcher.launcherEditMode
    onEditModeChanged: {
        if (launcherSettings.freeScroll) {
            return
        }
        if (editMode) {
            snapMode = ListView.NoSnap
            highlightRangeMode = ListView.NoHighlightRange
        } else {
            restoreSnapModeContentAnimation.to = originY + Math.round((contentY - originY) / height) * height
            restoreSnapMode.start()
        }
    }

    VerticalScrollDecorator {
        flickable: launcherPager
        visible: launcherSettings.freeScroll && launcherSettings.useScroll && launcherPager.contentHeight > launcherPager.height
    }

    model: ListModel {}
    delegate: Item {
        width: launcherPager.width
        height: launcherSettings.freeScroll ? launcher.cellHeight : launcherPager.height
    }
    snapMode: launcherSettings.freeScroll ? ListView.NoSnap : ListView.SnapOneItem
    highlightRangeMode: launcherSettings.freeScroll ? ListView.NoHighlightRange : ListView.StrictlyEnforceRange
    cacheBuffer: height*model.count
    maximumFlickVelocity: 4000*Theme.pixelRatio
    highlightMoveDuration: 300
    pressDelay: 0
    quickScroll: false
    interactive: !launcher.openedChildFolder && launcherActive

    function resetPosition(delay) {
        resetPositionTimer.interval = delay === undefined ? 1 : delay
        resetPositionTimer.restart()
    }

    Timer {
        id: resetPositionTimer
        onTriggered: if (!launcherActive) { launcherPager.positionViewAtBeginning() }
    }

    function scroll(up) {
        contentYAnimation.to = up ? 0 : contentHeight - launcherPager.height
        contentYAnimation.duration = Math.abs(contentY - contentYAnimation.to)
        contentYAnimation.start()
    }

    function stopScrolling() {
        contentYAnimation.stop()
    }

    NumberAnimation {
        id: contentYAnimation

        target: launcherPager
        property: "contentY"
    }

    SequentialAnimation {
        id: restoreSnapMode
        NumberAnimation {
            id: restoreSnapModeContentAnimation
            target: launcherPager
            property: "contentY"
            duration: 200
            easing.type: Easing.InOutQuad
        }
        ScriptAction {
            script: {
                launcherPager.currentIndex = Math.round((contentY - originY) / height)
                launcherPager.snapMode = ListView.SnapOneItem
                launcherPager.highlightRangeMode = ListView.StrictlyEnforceRange
            }
        }
    }

    Image {
        parent: launcherPager.contentItem
        y: launcherPager.originY
        anchors.horizontalCenter: parent.horizontalCenter
        source: "image://theme/graphic-edge-swipe-handle-bottom"
    }

    MouseArea {
        objectName: "Launcher"
        y: launcherPager.originY
        parent: launcherPager.contentItem
        width: launcherPager.width
        height: launcherPager.height * launcherPager.model.count

        property int pressX: 0
        property int pressY: 0
        onPressed: {
            pressX = mouse.x
            pressY = mouse.y
        }

        onPressAndHold: {
            if (Lipstick.compositor.launcherLayer.active &&
                Math.abs(mouse.x - pressX) < Theme.startDragDistance &&
                Math.abs(mouse.y - pressY) < Theme.startDragDistance) {
                launcher.setEditMode(true)
            }
        }
        onClicked: if (launcher.launcherEditMode) launcher.setEditMode(false)

        LauncherGrid {
            id: launcher

            launcherEditMode: removeApplicationEnabled && !openedChildFolder

            gridManager.onScroll: launcherPager.scroll(up)
            gridManager.onStopScrolling: launcherPager.stopScrolling()

            model: LauncherFolderModel {
                iconDirectories: Theme.launcherIconDirectories
                blacklistedApplications: {
                    // Currently desktop-file path is good app grid item
                    // identifier. However, this is a subject to change in future.
                    var blacklist = []
                    var path = "/usr/share/applications"
                    if (!developerModeEnabled.value) {
                        blacklist.push(path + "/fingerterm.desktop")
                    }

                    if (!AccessPolicy.cameraEnabled) {
                        blacklist.push(path + "/jolla-camera.desktop")
                        blacklist.push(path + "/jolla-camera-viewfinder.desktop")
                    }
                    
                    if (!AccessPolicy.browserEnabled) {
                        blacklist.push(path + "/sailfish-browser.desktop")
                    }

                    return blacklist
                }

                onNotifyLaunching: {
                    item.isLaunching = true
                    if (!item.isUpdating) {
                        Desktop.instance.switcher.activateWindowFor(item, false)
                    }
                }

                onApplicationRemoved: {
                    var switcher = Desktop.instance && Desktop.instance.switcher
                    if (switcher) {
                        switcher.closeCover(item)
                    }
                }
            }

            rootFolder: true
            interactive: false
            height: cellHeight * Math.ceil(count / columns)

            Component.onCompleted: manageDummyPages()
            onContentHeightChanged: manageDummyPages()
            onLauncherEditModeChanged: manageDummyPages()
            onColumnsChanged: manageDummyPages()
            onCountChanged: manageDummyPages()

            function manageDummyPages() {
                if (launcherPager.height > 0) {
                    // Create dummy pages to allow paging
                    var pageCount = launcherSettings.freeScroll ? Math.ceil(count / columns) : Math.ceil(contentHeight/launcherPager.height)
                    while (launcherPager.model.count < pageCount) {
                        launcherPager.model.append({ "name": "dummy" })
                    }
                    while (launcherPager.model.count > pageCount) {
                        launcherPager.model.remove(launcherPager.model.count-1)
                    }
                }
            }


            SilicaPrivate.VisibilityCull {
                target: launcher.contentItem
            }

            ConfigurationValue {
                id: developerModeEnabled
                defaultValue: false
                key: "/sailfish/developermode/enabled"
            }
        }
    }
}
