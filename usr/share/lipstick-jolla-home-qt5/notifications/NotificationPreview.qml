/****************************************************************************
 **
 ** Copyright (C) 2013 - 2020 Jolla Ltd.
 ** Copyright (C) 2020 Open Mobile Platform LLC.
 **
 ****************************************************************************/

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0 as Private
import Sailfish.Lipstick 1.0
import com.jolla.lipstick 0.1
import org.nemomobile.lipstick 0.1
import Nemo.Thumbnailer 1.0
import org.nemomobile.devicelock 1.0
import "../systemwindow"

SystemWindow {
    id: notificationWindow

    property QtObject notification: notificationPreviewPresenter.notification
    property bool showNotification: notification != null && (notification.previewBody || notification.previewSummary)
    property string summaryText: showNotification ? notification.previewSummary : ""
    property string bodyText: showNotification ? notification.previewBody : ""
    // we didn't earlier use app name on the popup so there can be transient notification that have only inferred
    // name set. As that's not always correct, showing transient notification name only if it's explicitly set.
    property string appNameText: notification != null ? (notification.isTransient ? notification.explicitAppName
                                                                                  : notification.appName)
                                                      : ""
    property string subText: notification != null ? notification.subText : ""
    property bool popupPresentation: state == "showPopup" || state == "hidePopup"
    property real statusBarPushDownY: bannerArea.y + bannerArea.height

    property string appIconUrl: notification != null && showNotification ? notification.appIcon : ""
    property bool _invoked

    property string pendingAction
    property QtObject pendingNotification

    Binding {
        // Invocation typically closes the notification, so bind the current values
        // to prevent unwanted changes to these properties and binding errors
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
        property: "appNameText"
        value: notificationWindow.appNameText
    }
    Binding {
        when: notificationWindow._invoked
        target: notificationWindow
        property: "subText"
        value: notificationWindow.subText
    }
    Binding {
        when: notificationWindow._invoked
        target: notificationWindow
        property: "appIconUrl"
        value: notificationWindow.appIconUrl
    }

    function firstLine(str) {
        var i = str.indexOf("\n")
        if (i >= 0) {
            return str.substr(0, i)
        }
        return str
    }

    function _indexOfAction(actionName) {
        var actions = notification.remoteActions
        var found = false
        for (var i = 0; i < actions.length; ++i) {
            if (actions[i].name === actionName) {
                return i
            }
        }
        return -1
    }

    function _triggerAction(actionName) {
        if (Desktop.deviceLockState !== DeviceLock.Unlocked) {
            pendingAction = actionName
            pendingNotification = notification
        } else {
            notificationWindow._invoked = true
            notification.actionInvoked(actionName)
        }

        // Always hide the notification preview after it is tapped
        notificationWindow.notificationExpired()

        // Also go to the switcher in case the screen was locked at invocation
        Lipstick.compositor.unlock()
    }

    onVisibleChanged: if (!visible) popupArea.expanded = false

    opacity: 0
    visible: false

    InverseMouseArea {
        id: outsideArea

        anchors.fill: popupArea
        enabled: false

        onPressedOutside: if (popupArea.expanded) notificationWindow.notificationExpired()
    }

    Binding {
        target: Lipstick.compositor.notificationOverviewLayer
        property: "previewExpanded"
        value: popupArea.expanded
    }

    Connections {
        target: Lipstick.compositor.lockScreenLayer
        onDeviceIsLockedChanged: {
            if (pendingAction.length > 0 && !Lipstick.compositor.lockScreenLayer.deviceIsLocked) {
                notificationWindow._invoked = true
                pendingNotification.actionInvoked(pendingAction)
                pendingAction = ""
            }
        }
        onShowingLockCodeEntryChanged: {
            if (!Lipstick.compositor.lockScreenLayer.showingLockCodeEntry) {
                pendingAction = ""
            }
        }
    }

    Connections {
        target: Lipstick.compositor
        onDisplayOff: notificationWindow.notificationExpired()
    }

    Private.SwipeItem {
        id: popupArea

        readonly property int baseX: Theme.paddingSmall

        property bool expanded
        property real textOpacity: 0
        property color textColor: down ? palette.highlightColor : palette.primaryColor
        readonly property int displayWidth: transpose ? Math.max(Screen.width, Screen.height/2)
                                                      : Screen.width - Theme.paddingSmall*2

        onSwipedAway: {
            notificationWindow.state = ""
            notificationWindow.notificationExpired()
        }

        objectName: "NotificationPreview_popupArea"

        _showPress: false
        y: Theme.paddingMedium
        width: displayWidth
        swipeDistance: notificationWindow.width
        height: expanded
                ? actionRow.y + (actionRow.visibleCount > 0 ? actionRow.height + Theme.paddingMedium : 0)
                : popupPreviewScrollContainer.height

        opacity: 0.0
        contentItem.clip: true
        palette.colorScheme: Theme.colorScheme == Theme.DarkOnLight ? Theme.LightOnDark : Theme.DarkOnLight

        Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.InQuad } }
        onClicked: {
            scrollAnimation.reset()
            if (notification && _indexOfAction("default") >= 0) {
                _triggerAction("default")
            } else {
                // Always hide the notification preview after it is tapped
                notificationWindow.notificationExpired()
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
            id: background

            property color _color: popupArea.palette.colorScheme == Theme.LightOnDark
                                   ? Qt.tint("#8A8A8A", Theme.rgba(Theme.highlightColor, 0.5))
                                   : Qt.tint("#FFFFFF", Theme.rgba(Theme.highlightColor, 0.3))

            anchors.fill: parent
            radius: Theme.paddingSmall
            color: Qt.tint(_color, Theme.rgba(popupArea.palette.highlightDimmerColor,
                                              popupArea.down ? Theme.opacityLow : 0))
            border.width: Math.round(Theme.pixelRatio)
            border.color: Qt.tint(_color, Theme.rgba(Theme.highlightColor, 0.1))
            opacity: popupArea.textOpacity

            NotificationAppIcon {
                id: appIcon

                anchors {
                    left: parent.left
                    leftMargin: Theme.paddingMedium
                    verticalCenter: popupPreviewScrollContainer.verticalCenter
                }
                width: Theme.iconSizeSmall + Theme.paddingSmall
                opacity: popupArea.textOpacity
                iconSource: notificationWindow.appIconUrl
                iconColor: notification ? notification.color : ""
            }

            HighlightImage {
                id: dropDownArrow

                anchors {
                    right: parent.right
                    verticalCenter: popupPreviewScrollContainer.verticalCenter
                }
                visible: !popupArea.expanded
                source: "image://theme/icon-m-change-type"
                highlighted: dropDownMouseArea.containsMouse
                color: palette.primaryColor
            }

            MouseArea {
                id: dropDownMouseArea

                anchors.fill: dropDownArrow
                anchors.margins: -Theme.paddingMedium
                enabled: dropDownArrow.visible

                onClicked: {
                    scrollAnimation.reset()
                    popupArea.expanded = true
                    outsideArea.enabled = true
                }
            }

            Item {
                id: popupPreviewScrollContainer

                anchors {
                    left: appIcon.right
                    leftMargin: Theme.paddingMedium
                    right: popupArea.expanded ? parent.right : dropDownArrow.left
                    rightMargin: popupArea.expanded ? Theme.paddingMedium : 0
                }
                height: Theme.itemSizeExtraSmall
                clip: true

                Row {
                    id: popupPreviewScroll

                    property bool showAppInfo: popupArea.expanded && (notificationWindow.appNameText != ""
                                                                      || notificationWindow.subText != "")

                    height: parent.height
                    spacing: Theme.paddingMedium
                    opacity: popupArea.textOpacity

                    // Text width has changed; recalculate whether text scrolling is necessary.
                    onWidthChanged: refreshPeriod()

                    Label {
                        id: topPrimaryLabel

                        anchors.verticalCenter: parent.verticalCenter
                        color: popupArea.textColor
                        font.pixelSize: Theme.fontSizeSmall
                        font.bold: true
                        textFormat: Text.PlainText
                        maximumLineCount: 1
                        visible: text != ""
                        text: popupPreviewScroll.showAppInfo
                              ? notificationWindow.appNameText
                              : firstLine(notificationWindow.summaryText)
                    }

                    Label {
                        id: topSecondaryLabel

                        anchors.verticalCenter: parent.verticalCenter
                        width: popupArea.expanded
                               ? popupPreviewScrollContainer.width
                                 - (topPrimaryLabel.text != "" ? (topPrimaryLabel.width + popupPreviewScroll.spacing) : 0)
                                 - popupPreviewScroll.spacing
                               : implicitWidth
                        color: popupArea.down ? palette.highlightColor
                                              : (popupArea.expanded ? palette.secondaryColor
                                                                    : palette.primaryColor)
                        truncationMode: TruncationMode.Fade
                        font.pixelSize: Theme.fontSizeSmall
                        maximumLineCount: 1
                        textFormat: Text.PlainText
                        text: popupArea.expanded
                              ? notificationWindow.subText
                              : firstLine(notificationWindow.bodyText)
                    }
                }
            }

            NotificationIcon {
                id: notificationIcon
                anchors {
                    top: popupPreviewScrollContainer.bottom
                    left: appIcon.right
                    leftMargin: Theme.paddingMedium
                }
            }

            Item {
                id: popupExpandedText

                anchors {
                    top: popupPreviewScrollContainer.bottom
                    left: notificationIcon.loaded ? notificationIcon.right : appIcon.right
                    leftMargin: Theme.paddingMedium
                    right: parent.right
                    rightMargin: Theme.paddingMedium
                }

                height: body.y + (body.visible ? body.implicitHeight : 0)

                Label {
                    id: summary

                    anchors {
                        left: parent.left
                        right: parent.right
                    }
                    color: popupArea.textColor
                    opacity: popupArea.textOpacity
                    truncationMode: TruncationMode.Fade
                    font.pixelSize: Theme.fontSizeMedium
                    font.bold: true
                    maximumLineCount: 1
                    visible: text.length > 0 && popupPreviewScroll.showAppInfo
                    height: visible ? implicitHeight : 0
                    textFormat: Text.PlainText
                    text: notificationWindow.summaryText
                }

                Label {
                    id: body

                    anchors {
                        top: summary.visible ? summary.bottom : parent.top
                        topMargin: summary.visible ? 0 : Theme.paddingMedium/2
                        left: summary.left
                        right: summary.right
                    }

                    color: popupArea.textColor
                    opacity: popupArea.textOpacity
                    truncationMode: TruncationMode.None
                    font.pixelSize: Theme.fontSizeSmall
                    visible: text.length > 0
                    maximumLineCount: (Screen.width/2) / bodyMetrics.height
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    text: notificationWindow.bodyText
                    elide: Text.ElideRight
                }

                FontMetrics {
                    id: bodyMetrics
                    font: body.font
                }
            }

            NotificationActionRow {
                id: actionRow

                onActionInvoked: _triggerAction(actionName)

                active: !notificationWindow._invoked
                anchors {
                    top: notificationIcon.loaded && notificationIcon.height > popupExpandedText.height ? notificationIcon.bottom
                                                                                                       : popupExpandedText.bottom
                    topMargin: Theme.paddingMedium
                    right: parent.right
                    rightMargin: Theme.paddingMedium
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
            // only one image shown so using fallbacks. image-path should be better than no image at all.
            source: {
                // don't use guessed appIcon on transient notifications, similar to appNameText
                if (notificationWindow.appIconUrl != "" && (!notification.isTransient
                                                            || notification.appIconOrigin != Notification.InferredValue)) {
                    return Notifications.iconSource(notificationWindow.appIconUrl)
                } else if (notification && notification.hints["image-path"] != "") {
                    return Notifications.iconSource(notification.hints["image-path"])
                }
                return ""
            }
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
            notificationTimer.duration = 3000
            notificationTimer.start()
        }
    }

    SequentialAnimation {
        id: notificationTimer
        property int duration
        paused: running && (popupArea.swipeActive || popupArea.showSwipeHint
                            || (notificationWindow.state === "showPopup" && popupArea.expanded))
        PauseAnimation {
            duration: notificationTimer.duration
        }
        ScriptAction {
            script: notificationWindow.notificationExpired()
        }
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
    onAppIconUrlChanged: refreshPeriod()

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
                var actions = notification.remoteActions
                // Show preview banner or pop-up
                var hasMultipleLines = (notification.previewSummary.length > 0 && notification.previewBody.length > 0)
                state = actions.length > 0 || hasMultipleLines ? "showPopup" : "showBanner"
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
        if (state == "showPopup" && !popupArea.expanded) {
            scroll = scrollAnimation.initialize(popupPreviewScroll, popupPreviewScrollContainer)
        } else if (state == "showBanner") {
            scroll = scrollAnimation.initialize(bannerArea, notificationWindow)
        }

        if (scroll) {
            scrollAnimation.start()
            forceHideTimer.start()
        } else {
            notificationTimer.duration = timeout
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
                target: popupArea
                x: popupArea.baseX
            }
            PropertyChanges {
                target: popupArea
                opacity: 1
                textOpacity: 1
            }
            PropertyChanges {
                target: popupPreviewScroll
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
                target: popupPreviewScroll
                // Keep the content at whatever scroll position it is currently in
                x: popupPreviewScroll.x
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
                PropertyAction {
                    target: popupArea
                    property: "expanded"
                    value: false
                }
                NumberAnimation {
                    target: popupArea
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
                    target: popupArea
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
                notificationTimer.duration = 2000
                notificationTimer.start()
            }
        }
    }
}
