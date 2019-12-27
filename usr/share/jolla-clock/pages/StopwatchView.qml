import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0
import "stopwatch" as StopWatch
import QtFeedback 5.0

TabItem {
    id: stopwatchPage

    property real labelHeight
    property ListModel stopwatch: StopWatch.StopwatchModel {}

    Component.onCompleted: {
        mainWindow.stopwatchMode = Qt.binding(function() { return isCurrentItem })
        mainWindow.stopwatch = stopwatch
    }
    SilicaListView {
        id: lapTimes

        height: parent.height
        clip: true
        rotation: 180
        model: stopwatch
        width: parent.width
        quickScroll: false
        currentIndex: 0
        onCurrentItemChanged: if (currentItem) labelHeight = currentItem.height
        remove: Transition { FadeAnimation { to: 0 } }

        delegate: StopWatch.StopwatchItem {
            id: stopwatchItem

            rotation: 180
            hourMode: stopwatch.hourMode
            text: stopwatch.formatTime(model.time)
            splitText: stopwatch.formatTime(model.splitTime)
            showSplit: Screen.sizeCategory > Screen.Medium || isLandscape
            hiddenSplit: lap === stopwatch.count
            width: parent.width
            color: lap === stopwatch.count ? Theme.highlightColor : Theme.secondaryHighlightColor
            //: Stopwatch lap
            //% "Lap"
            secondaryText: lap === stopwatch.count ? qsTrId("jolla-clock-le-lap") : lap
            ListView.onAdd: ParallelAnimation {
                NumberAnimation {
                    target: stopwatchItem
                    property: "opacity"
                    from: stopwatch.count == 1 ? 1.0 : 0.0
                    to: 1.0
                    duration: 200
                    easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    target: stopwatchItem
                    property: "height"
                    from: stopwatch.count == 1 ? stopwatchItem.height : 0
                    to: stopwatchItem.height
                    duration: 200
                    easing.type: Easing.InOutQuad
                }
            }
        }
        header: Column {
            rotation: 180
            anchors.horizontalCenter: parent.horizontalCenter
            Item { width: parent.width; height: Screen.sizeCategory > Screen.Medium ? Theme.paddingLarge : 0 }
            StopWatch.StopwatchItem {
                hourMode: stopwatch.hourMode
                color: mouseArea.down ? Theme.highlightColor : Theme.primaryColor
                text: stopwatch.formatTime(stopwatch.totalTime)
                showSplit: false
                anchors.horizontalCenter: parent.horizontalCenter
                //: Stopwatch total time
                //% "Total"
                secondaryText: qsTrId("jolla-clock-le-total")
                pixelSize: Screen.sizeCategory > Screen.Medium ? Theme.fontSizeHuge*2.25
                                                                : (hourMode ? Theme.fontSizeExtraLarge : Theme.fontSizeHuge)
            }
            Item { width: parent.width; height: Theme.paddingLarge }
        }
        MouseArea {
            id: mouseArea

            property bool down: pressed && containsMouse

            // tapping on top of footer and first item will behave like add/play button
            onClicked: {
                stopwatch.running ? stopwatch.nextLap() : stopwatch.start()
                lapTimes.positionViewAtBeginning()
            }

            rotation: 180
            parent: lapTimes.contentItem
            y: lapTimes.originY
            width: lapTimes.headerItem.width
            height: lapTimes.headerItem.height + labelHeight
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    ThemeEffect {
        id: themeEffect
        effect: ThemeEffect.PressWeak
    }
    IconButton {
        id: startLapButton
        x: Theme.horizontalPageMargin-Theme.paddingLarge
        anchors {
            bottom: parent.bottom
            bottomMargin: Screen.sizeCategory > Screen.Medium ? lapTimes.headerItem.height/2 - height/2
                                                               : lapTimes.headerItem.height + labelHeight/2 - height/2
        }
        icon.source: stopwatch.running ? "image://theme/icon-l-add" : "image://theme/icon-l-play"
        icon.sourceSize: Screen.sizeCategory > Screen.Medium ? Qt.size(Theme.itemSizeMedium, Theme.itemSizeMedium)
                                                             : Qt.size(Theme.iconSizeLarge, Theme.iconSizeLarge)
        onPressed: themeEffect.play()
        onClicked: {
            stopwatch.running ? stopwatch.nextLap() : stopwatch.start()
            lapTimes.positionViewAtBeginning()
        }
        width: icon.width + Theme.paddingLarge * 2
        height: icon.height + Theme.paddingLarge * 2
    }
    IconButton {
        anchors {
            right: parent.right
            rightMargin: Theme.horizontalPageMargin-Theme.paddingLarge
            bottom: parent.bottom
            bottomMargin: startLapButton.anchors.bottomMargin
        }
        icon.source: stopwatch.running ? "image://theme/icon-l-pause" : "image://theme/icon-l-clear"
        icon.sourceSize: startLapButton.icon.sourceSize
        onPressed: themeEffect.play()
        onClicked: stopwatch.running ? stopwatch.pause() : stopwatch.reset()
        width: icon.width + Theme.paddingLarge * 2
        height: icon.height + Theme.paddingLarge * 2
    }
}
