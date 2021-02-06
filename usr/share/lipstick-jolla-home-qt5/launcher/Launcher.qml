/*
 * Copyright (c) 2013 - 2018 Jolla Ltd.
 * Copyright (c) 2019 - 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.1
import org.nemomobile.lipstick 0.1
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0 as SilicaPrivate
import Sailfish.Policy 1.0
import Sailfish.AccessControl 1.0
import org.nemomobile.configuration 1.0
import Sailfish.Lipstick 1.0
import Nemo.DBus 2.0
import com.jolla.lipstick 0.1

SilicaListView {
    id: launcherPager

    property bool launcherActive: Lipstick.compositor.launcherLayer.active
    onLauncherActiveChanged: if (!launcherActive) { resetPosition(400) }

    property bool editMode: launcher.launcherEditMode
    onEditModeChanged: {
        if (editMode) {
            snapMode = ListView.NoSnap
            highlightRangeMode = ListView.NoHighlightRange
        } else {
            restoreSnapModeContentAnimation.to = originY + Math.round((contentY - originY) / height) * height
            restoreSnapMode.start()
        }
    }

    model: ListModel {}
    delegate: Item {
        width: launcherPager.width
        height: launcherPager.height
    }
    snapMode: ListView.SnapOneItem
    highlightRangeMode: ListView.StrictlyEnforceRange
    cacheBuffer: height*model.count

    // Match velocity with EdgeLayer transition's 300ms (0.3s below) duration
    maximumFlickVelocity: Math.max(Theme.maximumFlickVelocity, height / 0.3)
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

    function findClosestDelegate(x, y) {
        // Adjust here for center to do less calculations later
        var x = x - launcher.cellWidth/2
        var y = y - launcher.cellHeight/2
        var closest = null;
        // Square of Euclidean distance
        var distance = Infinity;
        var delegates = launcher.contentItem.children
        for (var i = 0; i < delegates.length; i++) {
            var delegate = delegates[i]
            if (!delegate.contentItem || delegate.contentItem.objectName !== "EditableGridDelegate_contentItem") {
                // In addition to EditableGridDelegates there are other items that we don't want
                continue
            }
            var d = Math.pow(x - delegate.x, 2) + Math.pow(y - delegate.y, 2)
            if (d < distance) {
                closest = delegate
                distance = d
            }
        }
        return closest
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
            if (Lipstick.compositor.launcherLayer.active && !launcher.launcherEditMode &&
                Math.abs(mouse.x - pressX) < Theme.startDragDistance &&
                Math.abs(mouse.y - pressY) < Theme.startDragDistance) {
                launcher.setEditMode(true)
                findClosestDelegate(mouse.x, mouse.y).animateScaleUp()
            }
        }
        onClicked: if (launcher.launcherEditMode) launcher.setEditMode(false)

        LauncherGrid {
            id: launcher
            property Item remorse
            property bool removeApplicationEnabled

            launcherEditMode: removeApplicationEnabled && !openedChildFolder

            gridManager.onScroll: launcherPager.scroll(up)
            gridManager.onStopScrolling: launcherPager.stopScrolling()

            model: LauncherFolderModel {
                property bool completed
                Component.onCompleted: completed = true

                iconDirectories: Theme.launcherIconDirectories
                blacklistedApplications: {
                    if (!completed)
                        return []

                    // Currently desktop-file path is good app grid item
                    // identifier. However, this is a subject to change in future.
                    var blacklist = AppBlacklist.list
                    var path = "/usr/share/applications"
                    if (!developerModeEnabled.value ||
                        !AccessControl.hasGroup(AccessControl.RealUid, "sailfish-system")) {
                        blacklist.push(path + "/fingerterm.desktop")
                    }

                    if (!AccessControl.hasGroup(AccessControl.RealUid, "sailfish-system")) {
                        blacklist.push(path + "/store-client.desktop")
                    }

                    if (!AccessPolicy.cameraEnabled) {
                        blacklist.push(path + "/jolla-camera.desktop")
                        blacklist.push(path + "/jolla-camera-viewfinder.desktop")
                    }
                    
                    if (!AccessPolicy.browserEnabled) {
                        blacklist.push(path + "/sailfish-browser.desktop")

                        // Blacklist links after LauncherFolderModel is populated.
                        // The model is initialized (loaded) upon component completed.
                        // Avoid binding loop to the itemCount as blacklisting alters count.
                        var i = 0
                        var item = get(i)
                        while (item) {
                            if (item.entryType === "Link") {
                                blacklist.push(item.filePath)
                            }

                            ++i
                            item = get(i)
                        }
                    }

                    return blacklist
                }

                onNotifyLaunching: {
                    item.isLaunching = true // TODO: Some leftover?
                    if (!item.isUpdating) {
                        Desktop.instance.switcher.activateWindowFor(item, false, true)
                    }
                }

                onCanceledNotifyLaunching: {
                    var switcher = Desktop.instance && Desktop.instance.switcher
                    if (switcher) {
                        switcher.closeCover(item, false)
                    }
                }

                onApplicationRemoved: {
                    var switcher = Desktop.instance && Desktop.instance.switcher
                    if (switcher) {
                        switcher.closeCover(item, true)
                    }
                }
            }

            rootFolder: true
            interactive: false
            height: cellHeight * Math.ceil(count / columns)

            Component.onCompleted: manageDummyPages()
            onContentHeightChanged: manageDummyPages()
            onLauncherEditModeChanged: manageDummyPages()

            function manageDummyPages() {
                if (launcherPager.height > 0) {
                    // Create dummy pages to allow paging
                    var pageCount = Math.ceil(contentHeight/launcherPager.height)
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

            function removeApplication(desktopFile, title) {
                if (!remorse) {
                    remorse = remorseComponent.createObject(launcherPager)
                } else if (remorse.desktopFile !== "" && remorse.desktopFile !== desktopFile) {
                    remorse.removePackageByDesktopFile()
                    remorse.cancel()
                }
                remorse.desktopFile = desktopFile

                //: Notification indicating that an application will be removed, %1 will be replaced by application name
                //% "Uninstalling %1"
                remorse.execute(qsTrId("lipstick-jolla-home-no-uninstalling").arg(title))
            }

            ConfigurationValue {
                id: developerModeEnabled
                defaultValue: false
                key: "/sailfish/developermode/enabled"
            }

            Component {
                id: remorseComponent

                RemorsePopup {
                    property string desktopFile

                    function removePackageByDesktopFile() {
                        if (desktopFile !== "") {
                            installationHandler.call("removePackageByDesktopFile", desktopFile)
                            desktopFile = ""
                        }
                    }

                    z: 100
                    onTriggered: removePackageByDesktopFile()
                    onCanceled: desktopFile = ""

                    DBusInterface {
                        id: installationHandler
                        service: "org.sailfishos.installationhandler"
                        path: "/org/sailfishos/installationhandler"
                        iface: "org.sailfishos.installationhandler"
                    }
                }
            }
        }
    }
}
