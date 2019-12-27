/****************************************************************************
**
** Copyright (C) 2013 Jolla Ltd.
** Contact: Vesa Halttunen <vesa.halttunen@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0 as Private
import Sailfish.Lipstick 1.0
import com.jolla.lipstick 0.1
import org.nemomobile.lipstick 0.1
import org.nemomobile.thumbnailer 1.0
import org.nemomobile.devicelock 1.0
import "../systemwindow"

SystemWindow {
    id: notificationWindow

    property QtObject notification: notificationPreviewPresenter.notification
    property bool showNotification: notification != null && (notification.previewBody || notification.previewSummary)
    property string summaryText: showNotification ? notification.previewSummary : ''
    property string bodyText: showNotification ? notification.previewBody : ''
    property bool popupPresentation: state == "showPopup" || state == "hidePopup"
    property string iconSource: showNotification ? (popupPresentation ? (notification.previewIcon || notification.icon || notification.appIcon)
                                                                      : (notification.previewIcon || notification.icon)) : ""
    property real statusBarPushDownY: bannerArea.y + bannerArea.height

    property string iconUrl: {
        if (iconSource.length) {
            if (iconSource.indexOf("http") === 0) {
                return iconSource
            } else if (iconSource.indexOf("/") === 0) {
                return "image://nemoThumbnail/" + iconSource
            } else if (iconSource.indexOf("image://theme/") === 0) {
                return iconSource
            } else {
                return "image://theme/" + iconSource
            }
        }
        return ''
    }

    property bool _invoked

    Binding {
        // Invocation typically closes the notification, so bind the current values
        // to prevent unwanted changes to these properties
        when: notificationWindow._invoked
        target: notificationWindow
        property: "summaryText"
        value: notificationWindow.summaryText
    }
    Binding {
        when: notificationWindow._invoked
        target: notificationWindow
        property: "bodyText"
        value: notificationWindow.bodyText
    }
    Binding {
        when: notificationWindow._invoked
        target: notificationWindow
        property: "iconUrl"
        value: notificationWindow.iconUrl
    }

    function firstLine(str) {
        var i = str.indexOf("\n")
        if (i >= 0) {
            return str.substr(0, i)
        }
        return str
    }

    opacity: 0
    visible: false

    HighlightImage {
        id: popupIcon

        property int baseX: Theme.horizontalPageMargin

        x: -width
        y: Theme.paddingMedium
        width: Theme.iconSizeSmall
        fillMode: Image.PreserveAspectFit
        verticalAlignment: Image.AlignTop
        source: notificationWindow.iconUrl ? notificationWindow.iconUrl : 'image://theme/icon-lock-information'
        sourceSize.width: width

        highlighted: popupArea.down
        highlightColor: Theme.highlightDimmerColor
        monochromeWeight: colorWeight
    }

    MouseArea {
        id: popupArea

        property bool down: pressed && containsMouse
        property real textOpacity: 0
        property color textColor: down ? Theme.highlightColor : Theme.primaryColor
        property real displayWidth: Theme.itemSizeSmall*5

        objectName: "NotificationPreview_popupArea"
        anchors {
            top: popupIcon.top
            left: popupIcon.right
            leftMargin: Theme.paddingSmall/2
        }
        width: displayWidth
        height: Math.max(Theme.itemSizeSmall, summary.y*2 + summary.height + bodyContainer.anchors.topMargin + bodyContainer.height)
        opacity: 0

        drag.minimumX: -parent.width
        drag.maximumX: parent.width
        drag.target: popupIcon
        drag.axis: Drag.XAxis
        drag.onActiveChanged: if (!drag.active) dismissAnimation.animate(popupIcon, popupIcon.baseX, parent.width)

        Private.DismissAnimation {
            id: dismissAnimation
            onCompleted: {
                notificationWindow.state = ""
                notificationWindow.notificationExpired()
            }
        }

        onClicked: {
            if (notification) {
                notificationWindow._invoked = true
                notification.actionInvoked("default")

                // Also go to the switcher in case the screen was locked at invocation
                Lipstick.compositor.unlock()
            }
        }
        onDownChanged: {
            if (!down) {
                if (!notificationTimer.running && !forceHideTimer.running) {
                    notificationWindow.notificationExpired()
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: Theme.paddingSmall
            color: Qt.tint(Theme.highlightBackgroundColor, Theme.colorScheme == Theme.LightOnDark ? Qt.rgba(0, 0, 0, Theme.opacityFaint)
                                                                                                  : Qt.rgba(1, 1, 1, Theme.opacityFaint))

            Rectangle {
                visible: popupArea.down
                anchors.fill: parent
                radius: parent.radius
                color: Theme.highlightDimmerColor
                opacity: Theme.opacityLow
            }

            Label {
                id: summary

                anchors {
                    top: parent.top
                    topMargin: Theme.paddingMedium/2
                    left: parent.left
                    leftMargin: Theme.paddingLarge
                    right: parent.right
                    rightMargin: Theme.paddingLarge
                }
                color: popupArea.textColor
                opacity: popupArea.textOpacity
                truncationMode: TruncationMode.Fade
                font.pixelSize: Theme.fontSizeSmall
                visible: text.length
                height: visible ? implicitHeight : 0
                textFormat: Text.PlainText
                maximumLineCount: 1
                // Only show the first line of the summary, if there is more
                text: firstLine(notificationWindow.summaryText)
            }

            Item {
                id: bodyContainer

                anchors {
                    top: summary.visible ? summary.bottom : parent.top
                    topMargin: summary.visible ? 0 : Theme.paddingMedium/2
                    left: summary.left
                    right: summary.right
                }
                clip: true
                height: body.height

                Label {
                    id: body

                    width: contentWidth
                    color: popupArea.textColor
                    opacity: popupArea.textOpacity
                    truncationMode: TruncationMode.None
                    font.pixelSize: Theme.fontSizeExtraSmall
                    visible: text.length
                    height: visible ? implicitHeight : 0
                    textFormat: Text.PlainText
                    maximumLineCount: 1
                    // Only show the first line of the body, if there is more
                    text: firstLine(notificationWindow.bodyText)
                }
            }
        }
    }

    MouseArea {
        id: bannerArea

        property real contentOpacity: 0

        width: Math.max(parent.width, bannerText.x + bannerText.width + Theme.paddingMedium)
        height: Lipstick.compositor.homeLayer.statusBar.height
        y: -height

        onClicked: notificationWindow.notificationExpired()

        Rectangle {
            anchors.fill: parent
            color: Theme.overlayBackgroundColor
            opacity: Theme.opacityHigh
        }

        Image {
            id: bannerIcon

            anchors {
                verticalCenter: bannerArea.verticalCenter
                left: bannerArea.left
                leftMargin: Theme.horizontalPageMargin
            }
            source: notificationWindow.iconUrl
            sourceSize.height: height
            height: Theme.iconSizeExtraSmall
            fillMode: Image.PreserveAspectFit
            opacity: bannerArea.contentOpacity
        }

        Label {
            id: bannerText

            anchors {
                verticalCenter: bannerIcon.verticalCenter
                left: bannerIcon.right
                leftMargin: Theme.paddingMedium
            }
            width: contentWidth
            truncationMode: TruncationMode.None
            font.pixelSize: Theme.fontSizeExtraSmall
            // If summary text but no body, use the summary as the body
            text: firstLine(notificationWindow.bodyText || notificationWindow.summaryText)
            visible: text != ""
            textFormat: Text.PlainText
            maximumLineCount: 1
            opacity: bannerArea.contentOpacity
        }
    }

    Loader {
        id: ambiencePreviewLoader
    }

    Component {
        id: ambiencePreviewComponent
        AmbiencePreview {
            onFinished: notificationWindow.notificationComplete()
        }
    }

    Binding {
        target: notificationFeedbackPlayer
        property: "minimumPriority"
        value: lipstickSettings.lockscreenVisible ? 100 : 0
    }

    Timer {
        id: displayTimer
        interval: 0
        repeat: false
        onTriggered: displayNotification()
    }

    Timer {
        id: forceHideTimer
        interval: 7000
        repeat: false
        onTriggered: {
            notificationTimer.interval = 3000
            notificationTimer.start()
        }
    }

    Timer {
        id: notificationTimer
        repeat: false
        onTriggered: notificationWindow.notificationExpired()
    }

    onNotificationChanged: {
        if (notification) {
            // Show notification only then unlocked or locked, so no notifications
            // in ManagerLockout, TemporaryLockout, PermanentLockout, or Undefined
            if (Desktop.deviceLockState == DeviceLock.Unlocked || Desktop.deviceLockState == DeviceLock.Locked) {
                displayTimer.restart()
            } else {
                // need to acknowledge all notifications
                notificationComplete()
            }
        } else if (state != "") {
            notificationExpired()
        }
    }

    function refreshPeriod() {
        if (scrollAnimation.running || notificationTimer.running || forceHideTimer.running) {
            forceHideTimer.stop()
            scrollAnimation.reset()

            // If the notification is already showing, restart the display period with a shorter timeout
            notificationShown(notificationTimer.running ? 3000 : 5000)
        }
    }

    onSummaryTextChanged: refreshPeriod()
    onBodyTextChanged: refreshPeriod()
    onIconUrlChanged: refreshPeriod()

    function displayNotification() {
        // We use two different presentation styles: one that can be clicked and one that cannot.
        // Check for configurations that can't be correctly activated
        if (notification.remoteActions.length == 0) {
            if (notification.previewSummary && notification.previewBody) {
                // Notifications with preview summary + preview body should have actions, as tapping on the preview pop-up should trigger some action
                console.log('Warning: Notification has both preview summary and preview body but no actions. Remove the preview body or add an action:', notification.appName, notification.category, notification.previewSummary, notification.previewBody)
            }
        } else {
            if (notification.previewSummary && !notification.previewBody) {
                // Notifications with preview summary but no body should not have any actions, as the small preview banner is too small to receive presses
                console.log('Warning: Notification has an action but only shows a preview summary. Add a preview body or remove the actions:', notification.appName, notification.category, notification.previewSummary, notification.previewBody)
            } else if ((!notification.previewSummary && !notification.previewBody) && notification.hints['transient'] == true) {
                console.log('Warning: Notification has actions but is transient and without a preview, its actions will not be triggerable from the UI:', notification.appName, notification.category, notification.previewSummary, notification.previewBody)
            }
        }

        if (showNotification) {
            if (notification.category === "x-jolla.ambience.preview") {
                ambiencePreviewLoader.sourceComponent = ambiencePreviewComponent
                var preview = ambiencePreviewLoader.item
                if (preview) {
                    preview.displayName = notification.previewSummary
                    preview.coverImage = notification.previewBody
                    preview.show()
                    state = "showAmbience"
                }
            } else {
                // Show preview banner or pop-up
                var hasActions = notification.remoteActions.length > 0
                var hasMultipleLines = (notification.previewSummary.length > 0 && notification.previewBody.length > 0)
                state = hasActions || hasMultipleLines ? "showPopup" : "showBanner"
            }
        }
    }

    function notificationShown(timeout) {
        // Min 1sec and max 5secs
        if (!timeout && notification.expireTimeout > 0) {
            timeout = Math.min(Math.max(notification.expireTimeout, 1000), 5000)
        } else {
            timeout = 5000
        }

        var scroll = false
        if (state == "showPopup") {
            scroll = scrollAnimation.initialize(body, bodyContainer)
        } else if (state == "showBanner") {
            scroll = scrollAnimation.initialize(bannerArea, notificationWindow)
        }

        if (scroll) {
            scrollAnimation.start()
            forceHideTimer.start()
        } else {
            notificationTimer.interval = timeout
            notificationTimer.restart()
        }
    }

    function notificationExpired() {
        forceHideTimer.stop()
        notificationTimer.stop()

        if (state == "showPopup") {
            state = "hidePopup"
        } else if (state == "showBanner") {
            state = "hideBanner"
        } else {
            notificationComplete()
        }
    }

    function notificationComplete() {
        state = ""
        _invoked = false
        notificationPreviewPresenter.showNextNotification()
    }

    states: [
        State {
            name: "showPopup"
            PropertyChanges {
                target: notificationWindow
                opacity: 1
                visible: true
            }
            PropertyChanges {
                target: popupIcon
                x: popupIcon.baseX
            }
            PropertyChanges {
                target: popupArea
                opacity: 1
                textOpacity: 1
            }
            PropertyChanges {
                target: body
                x: 0
            }
        },
        State {
            name: "hidePopup"
            PropertyChanges {
                target: notificationWindow
                opacity: 1
                visible: true
            }
            PropertyChanges {
                target: body
                // Keep the body at whatever scroll position it is currently in
                x: body.x
            }
        },
        State {
            name: "showBanner"
            PropertyChanges {
                target: notificationWindow
                opacity: 1
                visible: true
            }
            PropertyChanges {
                target: bannerArea
                y: 0
                x: 0
                contentOpacity: 1
            }
        },
        State {
            name: "hideBanner"
            PropertyChanges {
                target: notificationWindow
                opacity: 1
                visible: true
            }
            PropertyChanges {
                target: bannerArea
                // Keep the text at whatever scroll position it is currently in
                x: bannerArea.x
                contentOpacity: 1
            }
        },
        State {
            name: "showAmbience"
            PropertyChanges {
                target: notificationWindow
                opacity: 1
                visible: true
            }
        }
    ]

    transitions: [
        Transition {
            to: "showPopup"
            SequentialAnimation {
                NumberAnimation {
                    target: popupIcon
                    property: "x"
                    duration: 150
                    easing.type: Easing.OutQuad
                }
                ParallelAnimation {
                    NumberAnimation {
                        target: popupArea
                        property: "width"
                        duration: 200
                        from: popupArea.displayWidth * 0.9
                        to: popupArea.displayWidth
                        easing.type: Easing.OutQuad
                    }
                    SequentialAnimation {
                        NumberAnimation {
                            target: popupArea
                            property: "opacity"
                            duration: 50
                        }
                        NumberAnimation {
                            target: popupArea
                            property: "textOpacity"
                            duration: 150
                        }
                    }
                }
                ScriptAction {
                    script: notificationWindow.notificationShown()
                }
            }
        },
        Transition {
            to: "hidePopup"
            SequentialAnimation {
                ParallelAnimation {
                    SequentialAnimation {
                        NumberAnimation {
                            target: popupArea
                            property: "textOpacity"
                            duration: 150
                        }
                        NumberAnimation {
                            target: popupArea
                            property: "opacity"
                            duration: 50
                        }
                    }
                    NumberAnimation {
                        target: popupArea
                        property: "width"
                        duration: 200
                        from: popupArea.displayWidth
                        to: popupArea.displayWidth * 0.9
                        easing.type: Easing.InQuad
                    }
                }
                NumberAnimation {
                    target: popupIcon
                    property: "x"
                    duration: 150
                    easing.type: Easing.InQuad
                }
                ScriptAction {
                    script: notificationWindow.notificationComplete()
                }
            }
        },
        Transition {
            to: "showBanner"
            SequentialAnimation {
                ParallelAnimation {
                    PropertyAnimation {
                        target: bannerArea
                        property: "y"
                        duration: 200
                        easing.type: Easing.OutQuad
                    }
                    SequentialAnimation {
                        PauseAnimation { duration: 150 }
                        PropertyAnimation {
                            target: bannerArea
                            property: "contentOpacity"
                            duration: 150
                        }
                    }
                }
                ScriptAction {
                    script: {
                        notificationWindow.notificationShown()
                    }
                }
            }
        },
        Transition {
            to: "hideBanner"
            SequentialAnimation {
                PropertyAnimation {
                    target: bannerArea
                    property: "y"
                    duration: 200
                    easing.type: Easing.OutQuad
                }
                ScriptAction {
                    script: notificationWindow.notificationComplete()
                }
            }
        }
    ]

    SequentialAnimation {
        id: scrollAnimation

        function initialize(targetItem, containerItem) {
            target = targetItem
            container = containerItem
            return range > 0
        }

        function reset() {
            stop()
            if (target) {
                target.x = 0
                target = null
            }
        }

        property Item target
        property Item container
        property real range: target && container ? target.width - container.width : 0
        property real speed: 120
        property real accelerationDuration: 500

        PauseAnimation { duration: 2000 }
        PropertyAnimation {
            id: startScrollingAnimation

            target: scrollAnimation.target
            property: "x"
            from: 0
            to: Math.max(-scrollAnimation.range / 2, -scrollAnimation.speed * scrollAnimation.accelerationDuration / 1000 / 2)
            duration: (to - from) < 0 ? scrollAnimation.accelerationDuration : 0
            easing.type: Easing.InQuad
        }
        PropertyAnimation {
            property real animationDuration: -(to - from) * 1000 / scrollAnimation.speed

            target: scrollAnimation.target
            property: "x"
            from: startScrollingAnimation.to
            to: stopScrollingAnimation.from
            duration: Math.max(animationDuration, 0)
            easing.type: Easing.Linear
        }
        PropertyAnimation {
            id: stopScrollingAnimation

            target: scrollAnimation.target
            property: "x"
            from: Math.min(-scrollAnimation.range / 2, -scrollAnimation.range + scrollAnimation.speed * scrollAnimation.accelerationDuration / 1000 / 2)
            to: -scrollAnimation.range
            duration: (to - from) < 0 ? scrollAnimation.accelerationDuration : 0
            easing.type: Easing.OutQuad
        }
        ScriptAction {
            script: {
                scrollAnimation.target = null
                notificationTimer.interval = 2000
                notificationTimer.start()
            }
        }
    }
}
