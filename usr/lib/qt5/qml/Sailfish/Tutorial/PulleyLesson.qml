/*
 * Copyright (c) 2015 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import QtTest 1.0
import QtGraphicalEffects 1.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0
import Nemo.Time 1.0
import "private"

Lesson {
    id: root

    readonly property int columnCount: Math.floor(content.width / Theme.itemSizeHuge)
    readonly property real columnWidth: content.width / columnCount
    readonly property real zoomedOutScale: 0.88
    property bool _demonstrated

    //% "Now you know that the line at the top of the view is the pulley menu"
    recapText: qsTrId("tutorial-la-recap_tablet_pulley_menu")

    Component.onCompleted: {
        // Make sure the background is at correct position
        background.currentItem = background.switcherItem
        applicationGridIndicator.visible = false
        timeline.restart()
    }

    SequentialAnimation {
        id: timeline
        PauseAnimation { duration: 1000 }
        ScriptAction  {
            script: {
                fader.opacity = Theme.opacityOverlay
                //% "Here is Clock app"
                appInfo.text = qsTrId("tutorial-la-clock_app")
                appInfo.opacity = 1.0
                applicationGrid.y = 0
                touchBlocker.enabled = false
            }
        }
        PauseAnimation { duration: 3000 }
        ScriptAction  {
            script: {
                appInfo.opacity = 0.0
            }
        }
        PauseAnimation { duration: 1000 }
        ScriptAction  {
            script: {
                //% "Tap to open"
                appInfo.text = qsTrId("tutorial-la-tap_to_open")
                appInfo.opacity = 1.0
            }
        }
    }

    SequentialAnimation {
        id: openAppAnimation
        NumberAnimation {
            target: fader
            property: "opacity"
            to: 0.0
            duration: 100
        }
        NumberAnimation {
            target: appMainPage
            property: "opacity"
            to: 1.0
            duration: 500
        }
        PauseAnimation { duration: 1000 }
        ScriptAction  {
            script: {
                //% "The line at the top of the view indicates pulley menu which has additional options"
                hintLabel.text = qsTrId("tutorial-la-pulley_menu_description")
                hintLabel.opacity = 1.0
                hintLabel.showGradient = false
                pulleyMenu.busy = true
            }
        }
        PauseAnimation { duration: 2000 }
        ScriptAction  {
            script: {
                playButton.enabled = true
            }
        }
    }

    SequentialAnimation {
        id: timeline2
        ScriptAction  {
            script: {
                hint.stop()
                hintLabel.opacity = 0.0
                pulleyMenu.busy = false
                pulleyMenu.userAttempt = false
                playButton.enabled = false
            }
        }
        PauseAnimation { duration: 1000 }
        HandAnimation {
            hand: hand
            zoomItem: __silica_applicationwindow_instance._wallpaperItem
            zoomedOutScale: root.zoomedOutScale
            onPressed: {
                flickable.interactive = true
                touchInput.press()
            }
            onReleased: {
                touchInput.release()
                flickable.interactive = false
            }
        }
        PauseAnimation { duration: 1000 }
        ScriptAction  {
            script: {
                //% "Now it's your turn"
                hintLabel.text = qsTrId("tutorial-la-your_turn")
                hintLabel.opacity = 1.0
                hintLabel.showGradient = true
                root._demonstrated = true
            }
        }
        PauseAnimation { duration: 2000 }
        ScriptAction  {
            script: {
                hintLabel.opacity = 0.0
                timeline3.restart()
            }
        }
    }

    SequentialAnimation {
        id: timeline3
        ScriptAction  {
            script: {
                hintLabel.opacity = 0.0
            }
        }
        PauseAnimation { duration: 1000 }
        ScriptAction  {
            script: {
                //: 'New alarm' must match with clock-me-new_alarm
                //% "Pull down slowly without lifting your finger and select 'New alarm'"
                hintLabel.text = qsTrId("tutorial-la-clock_pull_down_slowly")
                hintLabel.opacity = 1.0
                hintLabel.opacityFadeDuration = 500 // quicker fade for cross-fade with overlayLabel
                hintLabel.showGradient = true
                pulleyMenu.userAttempt = true
                flickable.interactive = true
                hint.start()
                touchBlocker.enabled = false
            }
        }
    }

    SequentialAnimation {
        id: timeline4
        ScriptAction  {
            script: {
                touchBlocker.enabled = true
                playButton.enabled = false
                closeAnimation.restart()
                lessonCompleted()
            }
        }
    }

    SequentialAnimation {
        id: closeAnimation
        PauseAnimation { duration: 500 }
        FadeAnimation {
            target: appMainPage
            to: 0.0
            duration: 2000
        }
    }

    LauncherGrid {
        id: applicationGrid

        opacity: timeline2.running ? 0 : 1

        y: parent.height

        backgroundItem: homescreen

        Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }
    }

    LauncherItem {
        id: clockIcon

        row: 2
        column: 3

        enabled: applicationGrid.y === 0

        onClicked: {
            timeline.complete()
            touchBlocker.enabled = true
            enabled = false
            flickable.interactive = true
            timeline.stop()
            appInfo.opacity = 0.0
            applicationGrid.y = parent.height
            openAppAnimation.start()
        }
    }

    DimmedRegion {
        id: fader
        anchors.fill: parent
        opacity: 0.0
        target: mainPage
        area: Qt.rect(0, 0, parent.width, parent.height)
        exclude: [ clockIcon ]

        Behavior on opacity { FadeAnimation { duration: 500 } }
    }

    TapInteractionHint {
        running: clockIcon.enabled && appInfo.opacity === 1.0
        anchors.centerIn: clockIcon
    }

    InfoLabel {
        id: appInfo
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: clockIcon.bottom
            topMargin: 2 * Theme.paddingLarge
        }
        opacity: 0.0
        Behavior on opacity { FadeAnimation { duration: 500 } }
    }

    Item {
        id: homescreen

        anchors.fill: parent

        BackgroundImage {
            id: appMainPage

            anchors.top: parent.top
            parent: applicationBackground
            source: Screen.sizeCategory >= Screen.Large
                    ? Qt.resolvedUrl("file:///usr/share/sailfish-tutorial/graphics/tutorial-tablet-app-background.jpg")
                    : Qt.resolvedUrl("file:///usr/share/sailfish-tutorial/graphics/tutorial-phone-app-background.jpg")

            // Centering vertically
            y: (parent.height - height)/2

            opacity: 0.0
        }
    }

    SilicaFlickable {
        id: flickable

        anchors.fill: parent
        contentHeight: height
        opacity: appMainPage.opacity
        clip: true
        interactive: false

        // These are from SilicaFlickable, replicated here mainly so that we don't have BoundsBehavior
        property Item pullDownMenu
        property Item pushUpMenu
        property bool _pulleyDimmerActive: pullDownMenu && pullDownMenu._activeDimmer || pushUpMenu && pushUpMenu._activeDimmer
        pixelAligned: true
        pressDelay: 50
        boundsBehavior: (pullDownMenu && pullDownMenu._activationPermitted) || (pushUpMenu && pushUpMenu._activationPermitted)
                        ? Flickable.DragOverBounds : Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick

        Item {
            height: tabs.headerHeight
            width: parent.width

            TabView {
                id: tabs

                anchors.fill: parent
                currentIndex: 1
                _headerBackgroundVisible: false

                header: TabBar {
                    model: tabBarModel
                    enabled: false
                }

                model: [emptyView, emptyView, emptyView]

                Component {
                    id: emptyView
                    TabItem {}
                }
            }

            ListModel {
                id: tabBarModel

                ListElement {
                    //: Title of Timers tab page showing saved timers
                    //% "Timers"
                    title: qsTrId("clock-he-timers")
                }
                ListElement {
                    //: Title of Alarms tab page showing saved alarms
                    //% "Alarms"
                    title: qsTrId("clock-he-alarms")
                }
                ListElement {
                    //: Title of Stopwatch tab page with stopwatch counter
                    //% "Stopwatch"
                    title: qsTrId("clock-he-stopwatch")
                }
            }
        }

        Column {
            id: content

            x: Theme.horizontalPageMargin - Theme.paddingLarge
            width: parent.width - 2*x

            Item { width: 1; height: tabs.tabBarHeight }

            ClockItem {
                anchors.horizontalCenter: parent.horizontalCenter
                time: wallClockMinute.time
                primaryPixelSize: 124/480 * screen.width
                color: palette.highlightColor

                WallClock {
                    id: wallClockMinute
                    updateFrequency: WallClock.Minute
                }
            }

            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: dateText.width
                height: dateText.height + (Screen.sizeCategory > Screen.Medium ? Theme.itemSizeExtraSmall : Theme.paddingLarge)
                Label {
                    id: dateText
                    anchors {
                        top: parent.top
                        topMargin: -Theme.paddingMedium
                    }
                    color: palette.highlightColor

                    text: {
                        var dateString = Format.formatDate(wallClock.time, Format.DateFull)
                        return dateString.charAt(0).toUpperCase() + dateString.substr(1)
                    }

                    WallClock {
                        id: wallClock
                        updateFrequency: WallClock.Day
                    }
                }
            }

            Grid {
                id: alarmsView

                columns: columnCount
                width: parent.width

                Repeater {
                    model: alarmsModel
                    delegate: AlarmItem {
                        width: columnWidth
                    }
                }
            }
        }

        HintLabel {
            id: hintLabel
            opacity: 0.0
        }

        PullDownMenu {
            id: pulleyMenu

            property bool locked: pulleyMenu._atFinalPosition && !flickable.dragging
            property bool wasLocked
            property bool userAttempt

            onLockedChanged: {
                if (locked) {
                    // Remember the "locked" state until the menu is closed
                    wasLocked = true
                    pulleyHideTimer.restart()
                }
            }

            onActiveChanged: {
                if (userAttempt) {
                    if (active) {
                        hintLabel.opacity = 0.0
                        overlayLabel.opacity = 1.0
                        hint.stop()
                    } else {
                        if (!closeAnimation.running) {
                            hintLabel.opacity = 1.0
                            overlayLabel.opacity = 0.0
                            hint.start()
                        } else {
                            hintLabel.opacity = 0.0
                            overlayLabel.opacity = 0.0
                        }

                        // Forget the "locked" state
                        wasLocked = false
                        pulleyHideTimer.stop()
                    }
                }
            }

            MenuItem {
                //: Needs to match with clock-me-new_alarm
                //% "New alarm"
                text: qsTrId("tutorial-me-new_alarm")
                onClicked: {
                    if (pulleyMenu.userAttempt && !pulleyMenu.wasLocked) {
                        timeline4.restart()
                    }
                }
            }
        }
    }

    TouchInteractionHint {
        id: hint
        direction: TouchInteraction.Down
        interactionMode: TouchInteraction.Swipe
        loops: Animation.Infinite

        on_LoopsRunChanged: {
            if (_loopsRun === 1 && pulleyMenu.userAttempt && !playButton.enabled) {
                playButton.enabled = true
            }
        }
    }

    TouchBlocker {
        id: touchBlocker
        anchors.fill: parent
    }

    Button {
        id: playButton
        anchors {
            bottom: parent.bottom
            bottomMargin: 4 * Theme.paddingLarge
            horizontalCenter: parent.horizontalCenter
        }
        enabled: false
        text: root._demonstrated
                //% "Play again"
              ? qsTrId("tutorial-bt-play_again")
                //% "Play"
              : qsTrId("tutorial-bt-play")

        opacity: enabled ? 1 : 0
        Behavior on opacity {
            FadeAnimation {
                duration: root._demonstrated ? 400 : 1000
            }
        }

        onClicked: {
            enabled = false
            timeline3.stop()
            timeline2.restart()
            touchBlocker.enabled = true
        }

        InfoLabel {
            anchors {
                bottom: parent.top
                bottomMargin: 2 * Theme.paddingLarge
                horizontalCenter: parent.horizontalCenter
            }
            width: hintLabel.width
            visible: !root._demonstrated
            //% "See it in action"
            text: qsTrId("tutorial-la-see_it_in_action")
        }
    }

    HintLabel {
        id: overlayLabel

        parent: __silica_applicationwindow_instance
        atBottom: true
        opacity: 0.0

        text: pulleyMenu.locked
              //% "Pull down slower"
              ? qsTrId("tutorial-la-pull_slower")
              : pulleyMenu.active && !pulleyMenu.wasLocked
                //% "Select by releasing your finger when the option is highlighted"
                ? qsTrId("tutorial-la-select_new_timer")
                : ""

        Behavior on opacity { FadeAnimation { duration: 500 } }
    }

    Timer {
        id: pulleyHideTimer
        interval: 2000
        onTriggered: {
            pulleyMenu.hide()
        }
    }

    ListModel {
        id: alarmsModel

        Component.onCompleted: {
            append({
                "enabled": true,
                //: Example alarm title
                //% "Get up"
                "title": qsTrId("tutorial-alarm_model_get_up"),
                "hour": 6,
                "minute": 15,
                "daysOfWeek": "mtwTf"
            })

            append({
                "enabled": true,
                //: Example alarm title
                //% "School pickup"
                "title": qsTrId("tutorial-alarm_model_school_pickup"),
                "hour": 14,
                "minute": 45,
                "daysOfWeek": "mtwTf"
            })

            append({
                "enabled": false,
                //: Example alarm title
                //% "Lunch"
                "title": qsTrId("tutorial-alarm_model_lunch"),
                "hour": 12,
                "minute": 0,
                "daysOfWeek": "sS"
            })

            append({
                "enabled": true,
                //: Example alarm title
                //% "Gym"
                "title": qsTrId("tutorial-alarm_model_gym"),
                "hour": 18,
                "minute": 0,
                "daysOfWeek": "tTs"
            })
        }
    }

    TestEvent {
        id: touchInput

        // Update position as thumb rotates
        property var pos: hand.thumb.rotation, root.mapFromItem(hand.pressCircle, hand.pressCircle.width/2, hand.pressCircle.height/2)
        property bool pressed

        function press() {
            touchBlocker.enabled = false
            mousePress(flickable, pos.x, pos.y, Qt.LeftButton, 0, -1)
            touchBlocker.enabled = true
            pressed = true
        }

        function release() {
            touchBlocker.enabled = false
            mouseRelease(flickable, pos.x, pos.y, Qt.LeftButton, 0, -1)
            touchBlocker.enabled = true
            pressed = false
        }

        function move() {
            touchBlocker.enabled = false
            mouseMove(flickable, pos.x, pos.y, -1, Qt.LeftButton)
            touchBlocker.enabled = true
        }

        onPosChanged: {
            if (pressed) {
                move()
            }
        }
    }

    Hand {
        id: hand

        handScale: (Screen.sizeCategory >= Screen.Large ? 1 : 0.5) * xScale
        pressRotate: -2
        pressTranslate: 6
        dragRotate: Screen.sizeCategory >= Screen.Large ? -18 : -24
        dragTranslate: 50

        // Reverse the scaling of the app, to maintain the original size
        scale: 1 / __silica_applicationwindow_instance._wallpaperItem.scale
    }

    RadialGradient {
        id: metaBackground

        parent: __silica_applicationwindow_instance
        anchors.fill: parent
        z: -1
        visible: timeline2.running

        gradient: Gradient {
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 1) }
            GradientStop { position: 0.5; color: Qt.rgba(0, 0, 0, 1) }
            GradientStop { position: 0.4; color: Qt.rgba(0.3, 0.3, 0.3, 1) }
            GradientStop { position: 0.0; color: Qt.rgba(0.3, 0.3, 0.3, 1) }
        }
    }
}
