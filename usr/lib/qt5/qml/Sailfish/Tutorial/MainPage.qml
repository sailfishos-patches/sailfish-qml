/*
 * Copyright (c) 2014 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0
import Sailfish.Lipstick 1.0
import Sailfish.Tutorial 1.0
import "private"

TutorialPage {
    id: mainPage

    property alias background: pannable
    property alias applicationBackground: applicationBackgroundItem
    property alias applicationGridIndicator: swipeHandle
    property alias applicationSwitcher: switcher
    property int lessonCounter: 0
    property int maxLessons: lessons.length
    property bool showApplicationOverlay: false
    property bool showStatusBarClock: false

    // This date and time is hard-coded in some of the graphical assets as well.
    property date tutorialDate: new Date(2015, 5, 8, 17, 07, 0)

    property real baseWidth: Screen.sizeCategory >= Screen.Large ? 1536 : 540
    property real baseHeight: Screen.sizeCategory >= Screen.Large ? 2048 : 960
    property real xScale: width / baseWidth
    property real yScale: height / baseHeight

    property var lessons: []

    onStatusChanged: {
        if (status === PageStatus.Active && lessonCounter === 0) {
            pannable.opacity = 1
            recap.show(1)
        }
    }

    function buildLessons() {
        if (lessons.length > 0)
            return

        lessons = [ "HomeLesson.qml", "LauncherLesson.qml",
                   "SwipeLesson.qml", "PageStackLesson.qml", "PulleyLesson.qml"]
    }

    function lessonCompleted(pauseDuration) {
        // Restore homescreen courasel pannable items
        pannable.pannableItems = [ pannable.switcherItem ]

        if (lessonCounter === maxLessons)
            showApplicationOverlay = false

        if (lessonLoader.item && lessonLoader.item.recapText !== "") {
            recap.show(pauseDuration)
        } else {
            lessonCounter++
            showLesson()
        }
    }

    function showLesson() {
        // Reset source in order to make sure a new instance is always created
        lessonLoader.source = ""

        var index = lessonCounter - 1
        if (index < lessons.length) {
            lessonLoader.source = Qt.resolvedUrl(lessons[index])
        } else {
            __silica_applicationwindow_instance.deactivate()
            delayedQuit.restart()
        }
    }

    Timer {
        id: delayedQuit
        interval: 400   // wait for window fade out
        onTriggered: {
            Qt.quit()
        }
    }

    Pannable {
        id: pannable

        property bool allowPanLeft: false
        property bool allowPanRight: false

        property Item switcherItem: PannableItem {
            width: pannable.width
            height: pannable.height

            Switcher {
                id: switcher

                y: baseY
                statusBarHeight: statusIndicator.y + statusIndicator.height
                visible: opacity > 0
                opacity: showApplicationOverlay ? 1 : 0
                Behavior on opacity { FadeAnimation { duration: 300 } }
            }
        }

        // Interaction requires parent to be mainPage, but during lessons parent needs to be
        // homeContainer for correct stacking order.
        parent: pan ? mainPage : homeContainer
        anchors.fill: parent
        opacity: 0

        pan: allowPanLeft || allowPanRight

        Behavior on opacity { FadeAnimation { duration: 1000 } }

        BackgroundImage {
            z: -1
            source: Screen.sizeCategory >= Screen.Large
                    ? Qt.resolvedUrl("file:///usr/share/sailfish-tutorial/graphics/tutorial-tablet-wallpaper.jpg")
                    : Qt.resolvedUrl("file:///usr/share/sailfish-tutorial/graphics/tutorial-phone-wallpaper.jpg")
        }

        Rectangle {
            anchors.fill: parent
            z: -1

            opacity: {
                var currentItemDim = pannable.currentItem && pannable.currentItem.hasOwnProperty("dimBackground") ? pannable.currentItem.dimBackground : false
                var alternateItemDim = pannable.alternateItem && pannable.alternateItem.hasOwnProperty("dimBackground") ? pannable.alternateItem.dimBackground : false

                if (!pannable.moving) {
                    return currentItemDim ? Theme.opacityHigh : 0
                } else {
                    if (!currentItemDim && alternateItemDim)
                        return pannable.progress / 2
                    else if (currentItemDim && !alternateItemDim)
                        return (1 - pannable.progress) / 2
                    else if (currentItemDim && alternateItemDim)
                        return Theme.opacityHigh
                    else
                        return 0
                }
            }
            color: mainPage.palette.highlightDimmerColor
        }

        currentItem: switcherItem

        pannableItems: [ switcherItem ]
        onPannableItemsChanged: updatePannableItems()
        onAllowPanLeftChanged: updatePannableItems()
        onAllowPanRightChanged: updatePannableItems()

        function updatePannableItems() {
            if (pannableItems.length === 1) {
                pannableItems[0].leftItem = null
                pannableItems[0].rightItem = null
                return
            }

            for (var i = 0; i < pannableItems.length; ++i) {
                pannableItems[i].leftItem = (currentItem !== pannableItems[i] || allowPanLeft)
                                            ? pannableItems[(i - 1 + pannableItems.length) % pannableItems.length]
                                            : null

                pannableItems[i].rightItem = (currentItem !== pannableItems[i] || allowPanRight)
                                             ? pannableItems[(i + 1) % pannableItems.length]
                                             : null
            }
        }

        Item {
            id: statusIndicator

            y: Theme.paddingMedium + Theme.paddingSmall
            width: parent.width
            height: batteryIndicator.height

            BatteryStatusIndicator {
                id: batteryIndicator

                color: palette.primaryColor
            }

            ClockItem {
                anchors.centerIn: parent

                time: tutorialDate
                primaryPixelSize: Theme.fontSizeMedium

                opacity: showStatusBarClock ? 1 : 0
                Behavior on opacity { FadeAnimation { } }
            }

            ConnectionStatusIndicator {
                property real iconWidth: Theme.iconSizeExtraSmall
                property size iconSize: Qt.size(iconWidth,iconWidth)
                property string iconSuffix: ""

                anchors {
                    right: parent.right
                    rightMargin: Theme.paddingMedium
                    verticalCenter: parent.verticalCenter
                }
            }
        }

        Image {
            id: swipeHandle

            source: "image://theme/graphic-edge-swipe-handle-top"

            anchors {
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
            }
        }
    }

    IconGridViewBase {
        id: launcherLayout

        // from Home LauncherGrid
        property real topMargin: Screen.sizeCategory >= Screen.Large ? Theme.paddingLarge*4
                                                                     : Theme.paddingSmall
        height: parent.height
    }

    Item {
        id: applicationBackgroundItem

        parent: __silica_applicationwindow_instance._wallpaperItem
        anchors.fill: parent

        Item {
            id: homeContainer

            anchors.fill: parent
        }
    }

    Loader {
        id: lessonLoader

        z: 1
        anchors.fill: parent
        onSourceChanged: swipeHandle.visible = true
    }

    RecapItem {
        id: recap

        z: 1
        recapText: lessonLoader.item ? lessonLoader.item.recapText : ""
    }

    Component.onCompleted: buildLessons()
}
