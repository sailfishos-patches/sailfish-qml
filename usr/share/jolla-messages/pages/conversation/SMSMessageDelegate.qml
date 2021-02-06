/*
 * Copyright (c) 2013 - 2020 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0
import Sailfish.Silica.Background 1.0
import Sailfish.Messages 1.0
import Sailfish.TextLinking 1.0
import org.nemomobile.commhistory 1.0
import org.nemomobile.messages.internal 1.0

ListItem {
    id: message

    contentHeight: Math.max(timestamp.y + (timestamp.height ? (timestamp.height) : -Theme.paddingSmall),
                            messageText.y + messageText.height,
                            retryIcon.height)
                   + Theme.paddingMedium
                   + (groupFirst ? Theme.paddingSmall : 0)

    Behavior on contentHeight {
        NumberAnimation {
            id: contentHeightAnimation
            duration: 100
            easing.type: Easing.InOutQuad
        }
    }

    menu: messageContextMenu

    // NOTE: press effect is provided by the rounded rectangle, so we disable the one provided by ListItem
    _backgroundColor: "transparent"

    property QtObject modelData
    property int modemIndex: MessageUtils.simManager.indexOfModemFromImsi(modelData.subscriberIdentity)
    property bool inbound: modelData ? modelData.direction == CommHistory.Inbound : false
    property bool hasAttachments: modelData.messageParts.length > 0
                                  || attachmentOverlay.visible
    property bool hasText
    property bool canRetry
    property int eventStatus
    property string eventStatusText: modelData ? mainWindow.eventStatusText(eventStatus, modelData.eventId) : ""

    property date currentDateTime
    property bool showDetails
    property bool hideDefaultTimestamp: modelData && (calculateDaysDiff(modelData.startTime, currentDateTime) > 6 && modelData.index !== 0)
    property bool groupFirst
    property bool groupLast

    function calculateDaysDiff(date, currentDateTime) {
        // We use different formats depending on the age for the message, compared to the
        // current day. To match Formatter, counts days difference using date component only.
        var today = new Date(currentDateTime).setHours(0, 0, 0, 0)
        var messageDate = new Date(date).setHours(0, 0, 0, 0)

        return (today - messageDate) / (24 * 60 * 60 * 1000)
    }

    function formatDate(date, currentDateTime, shorten) {
        var daysDiff = calculateDaysDiff(date, currentDateTime)
        var dateString
        var timeString

        if (daysDiff > 6) {
            dateString = Format.formatDate(date, (daysDiff > 365 ? Formatter.DateMedium : Formatter.DateMediumWithoutYear))
            timeString = Format.formatDate(date, Formatter.TimeValue)
        } else if (daysDiff > 0) {
            dateString = Format.formatDate(modelData.startTime, Formatter.WeekdayNameStandalone)
            timeString = Format.formatDate(date, Formatter.TimeValue)
        } else if (shorten) {
            timeString = Format.formatDate(date, Formatter.DurationElapsedShort)
        } else {
            timeString = Format.formatDate(date, Formatter.DurationElapsed)
        }

        if (dateString) {
            return qsTrId("messages-la-date_time").arg(dateString).arg(timeString)
        } else {
            return timeString
        }
    }

    function formatDetailedDate(date, currentDateTime) {
        var daysDiff = calculateDaysDiff(date, currentDateTime)
        var dateString
        var timeString = Format.formatDate(date, Formatter.TimeValue)

        if (daysDiff < 365) {
            dateString = Format.formatDate(date, Formatter.DateFullWithoutYear)
        } else {
            dateString = Format.formatDate(date, Formatter.DateFull)
        }

        return qsTrId("messages-la-date_time").arg(dateString).arg(timeString)
    }

    ColorBackground {
        id: bubble

        property int fullMessageWidth: (hasText ? (messageText.contentWidth + 2 * messageText.horizontalMargin) : 0)
                                       + ((timestamp.mergeTimestamp && messageText.lineCount === 1)
                                          ? (timestamp.width + Theme.paddingMedium) : 0)
                                       + (hasAttachments
                                          ? (attachments.width + attachments.anchors.leftMargin
                                             + attachments.anchors.rightMargin
                                             + (!hasText ? Theme.paddingLarge : 0))
                                          : 0)
        property int extendedTimestampWidth: {
            if (inbound) {
                return timestamp.x + timestamp.width
            } else {
                return parent.width - timestamp.x
            }
        }

        anchors {
            left: inbound ? parent.left : undefined
            right: !inbound ? parent.right : undefined
            top: parent.top
            bottom: parent.bottom
            leftMargin: inbound ? Theme.paddingMedium : 0
            rightMargin: inbound ? 0 : Theme.paddingMedium
            topMargin: Theme.paddingSmall
            bottomMargin: (groupFirst ? Theme.paddingSmall : 0)
        }

        radius: Theme.paddingLarge
        roundedCorners: {
            // Note: MessagesView has a BottomToTop layout direction, so groupFirst is the bottom-most
            var result = Corners.None
            result |= inbound ? Corners.BottomRight : Corners.BottomLeft
            if (message.groupLast) {
                result |= inbound ? Corners.TopLeft : Corners.TopRight
            }
            return result
        }

        opacity: {
            if (message.highlighted) {
                return Theme.opacityHigh
            }

            return inbound ? Theme.opacityHigh : Theme.opacityFaint
        }

        width: Math.max(fullMessageWidth, extendedTimestampWidth, radius * 2)

        Behavior on width {
            NumberAnimation {
                duration: contentHeightAnimation.duration
                easing.type: Easing.InOutQuad
            }
        }

        color: {
            if (menuOpen) {
                return "transparent"
            } if (message.highlighted) {
                return Theme.rgba(Theme.highlightBackgroundColor, Theme.highlightBackgroundOpacity)
            } if (Theme.colorScheme === Theme.DarkOnLight) {
                return Theme.rgba(Theme.highlightColor, Theme.opacityFaint)
            }

            return Theme.rgba(Theme.primaryColor, Theme.opacityFaint)
        }
    }

    // Retry icon for non-attachment outbound messages
    Image {
        id: retryIcon
        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
            margins: Theme.horizontalPageMargin
        }
    }

    Column {
        id: attachments
        height: Math.max(implicitHeight, attachmentOverlay.height)
        width: Math.max(implicitWidth, attachmentOverlay.width)
        anchors {
            left: inbound ? bubble.left : undefined
            leftMargin: inbound ? (width ? Theme.paddingMedium : 0) : 0
            right: inbound ? undefined : bubble.right
            rightMargin: inbound ? 0 : (width ? Theme.paddingMedium : 0)
            // We really want the baseline of the last line of text, but there's no way to get that
            bottom: messageText.bottom
        }

        Repeater {
            id: attachmentLoader
            model: modelData.messageParts

            AttachmentDelegate {
                anchors {
                    left: inbound ? parent.left : undefined
                    right: inbound ? undefined : parent.right
                }
                messagePart: modelData
                // Retry icon for attachment outbound messages
                showRetryIcon: message.canRetry
                highlighted: message.highlighted
            }
        }
    }

    BackgroundItem {
        anchors.fill: attachments
        enabled: modelData.messageParts.length > 0
        onClicked: pageStack.animatorPush(Qt.resolvedUrl("../MessagePartsPage.qml"),
                                          { 'modelData': modelData, 'eventStatus': eventStatus })
    }

    Item {
        id: attachmentOverlay

        width: height
        height: (busyLoader.active || progressLoader.active || attachmentRetryIcon.status === Image.Ready)
                ? Theme.itemSizeLarge : 0
        visible: height > 0
        anchors {
            left: attachments.left
            bottom: attachments.bottom
        }

        Rectangle {
            anchors.fill: parent
            color:  modelData.messageParts.length ? Theme.highlightDimmerColor : Theme.highlightColor
            opacity: modelData.messageParts.length ? Theme.opacityHigh : Theme.opacityFaint
        }

        Loader {
            id: busyLoader
            active: (eventStatus === CommHistory.DownloadingStatus
                     || eventStatus === CommHistory.WaitingStatus
                     || (eventStatus === CommHistory.SendingStatus && modelData.eventType === CommHistory.MMSEvent))
                    && !(progressLoader.active && progressLoader.item && progressLoader.item.visible)
            anchors.centerIn: parent
            sourceComponent: BusyIndicator {
                running: true
            }
        }

        Loader {
            id: progressLoader
            active: (modelData.eventType === CommHistory.MMSEvent) && (eventStatus === CommHistory.DownloadingStatus
                                                                       || eventStatus === CommHistory.SendingStatus)
            anchors.centerIn: parent
            sourceComponent: ProgressCircle {
                visible: transfer.running // running = progress is known, greater than 0 and less than 1
                value: transfer.progress
                inAlternateCycle: true
                MmsMessageProgress {
                    id: transfer
                    path: "/msg/" + modelData.eventId + (inbound ? "/Retrieve" : "/Send")
                    inbound: eventStatus === CommHistory.DownloadingStatus
                }
            }
        }

        // Retry icon for inbound messages (in attachment style)
        Image {
            id: attachmentRetryIcon
            anchors.centerIn: parent
        }
    }

    LinkedText {
        id: messageText
        anchors {
            top: bubble.top
            left: inbound ? attachments.right : undefined
            right: inbound ? undefined : attachments.left
            topMargin: Theme.paddingMedium
            leftMargin: horizontalMargin
                        - (effectiveHorizontalAlignment === Text.AlignRight ? marginCorrection : 0)
                        + (inbound ? timestampMarginCorrection : 0)
            rightMargin: horizontalMargin
                         - (effectiveHorizontalAlignment === Text.AlignLeft ? marginCorrection : 0)
                         + (!inbound ? timestampMarginCorrection : 0)
        }

        property int lastLineWidth
        property int lastLineHeight
        property bool layoutDone
        property int horizontalMargin: Theme.paddingMedium
        property int sidePadding: Theme.itemSizeSmall + Theme.horizontalPageMargin
        property int marginCorrection: width - Math.ceil(contentWidth)
        property int timestampMarginCorrection: {
            if (!timestamp.mergeTimestamp || lineCount > 1) {
                return 0
            } else if (inbound && effectiveHorizontalAlignment === Text.AlignRight) {
                return timestampRow.width + horizontalMargin
            } else if (!inbound && effectiveHorizontalAlignment === Text.AlignLeft) {
                return timestampRow.width + horizontalMargin
            }
            return 0
        }
        Behavior on timestampMarginCorrection {
            NumberAnimation {
                easing.type: Easing.InOutQuad
                duration: contentHeightAnimation.duration
            }
        }

        y: Theme.paddingMedium / 2
        height: Math.max(implicitHeight, implicitHeight ? attachments.height : 0)
        width: parent.width
               - (hasAttachments ? (Theme.itemSizeLarge + Theme.paddingMedium) : 0)
               - (retryIcon.width > 0 ? (2 * Theme.horizontalPageMargin + retryIcon.width + 2 * Theme.paddingMedium) : sidePadding)

        plainText: {
            if (!modelData) {
                hasText = false
                return ""
            } else if (modelData.freeText !== "") {
                hasText = true
                return modelData.freeText
            } else if (modelData.subject !== "") {
                hasText = true
                return modelData.subject
            } else {
                hasText = false
                return ""
            }
        }

        onLineLaidOut: {
            if (line.isLast) {
                lastLineWidth = line.implicitWidth
                lastLineHeight = line.height
                layoutDone = true
            } else {
                layoutDone = false
            }
        }

        color: (message.highlighted || !inbound) ? Theme.highlightColor : Theme.primaryColor
        linkColor: inbound || message.highlighted ? Theme.highlightColor : Theme.primaryColor
        font.pixelSize: Theme.fontSizeSmall
    }

    Column {
        id: timestamp

        readonly property int mergedTimestampLtrX: messageText.lastLineWidth + Theme.paddingMedium
        readonly property int mergedTimestampRtlX: messageText.contentWidth + messageText.marginCorrection
                                                   - mergedTimestampLtrX - timestamp.width
        readonly property bool canMergeTimestamp: messageText.layoutDone // Ensure that the message text is fully laid out
                                                  && (width > 0) // Ensure that the timestamp is laid out as well
                                                  && !hideDefaultTimestamp // Never merge if the timestamp is hidden by default
                                                  && (messageText.lineCount === 1 // Check if we have room for the timestamp
                                                      ? (mergedTimestampLtrX + width) <= messageText.width
                                                      : (mergedTimestampLtrX + width) <= messageText.contentWidth)
        readonly property bool mergeTimestamp: !showDetails && canMergeTimestamp

        anchors {
            left: inbound ? parent.left : undefined
            leftMargin: {
                if (!inbound) {
                    return 0
                } else if (mergeTimestamp) {
                    return bubble.anchors.leftMargin + messageText.anchors.leftMargin
                           + (messageText.effectiveHorizontalAlignment === Text.AlignLeft ? mergedTimestampLtrX : mergedTimestampRtlX)
                           + (hasAttachments ? (attachments.width + Theme.paddingMedium) : 0)
                } else {
                    return Theme.paddingMedium + bubble.anchors.leftMargin
                }
            }
            right: !inbound ? parent.right : undefined
            rightMargin: {
                if (inbound) {
                    return 0
                } else if (mergeTimestamp) {
                    return bubble.anchors.rightMargin + messageText.anchors.rightMargin
                           + (messageText.effectiveHorizontalAlignment === Text.AlignLeft ? mergedTimestampRtlX : mergedTimestampLtrX)
                           + (hasAttachments ? (attachments.width + Theme.paddingMedium) : 0)
                } else {
                    return Theme.paddingMedium + bubble.anchors.rightMargin
                }
            }
            top: mergeTimestamp ? messageText.baseline : messageText.bottom
            topMargin: mergeTimestamp ? (-height) : Theme.paddingSmall
        }
        opacity: Theme.opacityHigh
        height: (showDetails && detailedTimestampLoader.item) ? detailedTimestampLoader.item.height : implicitHeight

        Row {
            id: timestampRow

            spacing: Theme.paddingSmall
            visible: !showDetails && (!!timestampLabel.text || warningIcon.visible)
            height: Theme.iconSizeSmall // Avoid height flicker when details has just one visible row
            anchors {
                left: inbound ? parent.left : undefined
                right: inbound ? undefined : parent.right
            }

            Label {
                id: timestampLabel

                color: messageText.color
                font.pixelSize: Theme.fontSizeExtraSmall
                anchors.baselineOffset: timestamp.mergeTimestamp ? (messageText.height - messageText.lastLineHeight + timestamp.height) : 0
                text: {
                    if (eventStatusText)
                        return eventStatusText
                    if (hideDefaultTimestamp)
                        return ""
                    return formatDate(modelData.startTime, currentDateTime, true)
                }
                states: State {
                    when: timestamp.mergeTimestamp
                    AnchorChanges {
                        target: timestampLabel
                        anchors.baseline: parent.top
                    }
                }
            }

            HighlightImage {
                id: warningIcon

                visible: false
                highlighted: message.highlighted
                source: "image://theme/icon-s-warning"
                color: timestampLabel.color
                anchors.verticalCenter: timestampLabel.verticalCenter
            }
        }

        Loader {
            id: detailedTimestampLoader
            sourceComponent: detailedTimestampComponent
            active: showDetails
            visible: !!item
            opacity: 0.0
        }
    }

    Component {
        id: detailedTimestampComponent

        Column {
            spacing: Theme.paddingSmall

            Label {
                anchors {
                    left: inbound ? parent.left : undefined
                    right: inbound ? undefined : parent.right
                }
                visible: !!text
                color: messageText.color
                font.pixelSize: Theme.fontSizeExtraSmall
                text: MessageUtils.phoneDetailsString(inbound ? modelData.remoteUid : modelData.localUid, conversation.people)
            }

            Row {
                spacing: Theme.paddingSmall
                height: Theme.iconSizeSmall // Avoid height flicker when delivered icon appears
                anchors {
                    left: inbound ? parent.left : undefined
                    right: inbound ? undefined : parent.right
                }

                HighlightImage {
                    id: simIcon

                    anchors.verticalCenter: parent.verticalCenter
                    highlighted: message.highlighted
                    visible: MessageUtils.multipleEnabledSimCards && message.modemIndex >= 0 && message.modemIndex <= 1
                    source: {
                        if (message.modemIndex === 0)
                            return "image://theme/icon-s-sim1"
                        else if (message.modemIndex === 1)
                            return "image://theme/icon-s-sim2"
                    }
                    color: messageText.color
                }

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: Theme.fontSizeExtraSmall
                    visible: simIcon.visible
                    color: simIcon.color
                    text: message.modemIndex >= 0 ? MessageUtils.simManager.modemSimModel.get(message.modemIndex)["operator"] : ""
                }

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: Theme.fontSizeExtraSmall
                    visible: simIcon.visible
                    color: simIcon.color
                    text: "|"
                }

                Label {
                    color: timestampLabel.color
                    font.pixelSize: Theme.fontSizeExtraSmall
                    anchors.verticalCenter: parent.verticalCenter
                    text: {
                        if (eventStatusText)
                            return eventStatusText
                        return formatDetailedDate(modelData.startTime, currentDateTime)
                    }
                }

                HighlightImage {
                    visible: message.showDetails && (modelData.readStatus === CommHistory.ReadStatusRead
                                                     || eventStatus === CommHistory.DeliveredStatus)
                    highlighted: message.highlighted
                    source: "image://theme/icon-s-checkmark"
                    color: timestampLabel.color
                    anchors.verticalCenter: parent.verticalCenter
                }

                HighlightImage {
                    visible: warningIcon.visible
                    highlighted: message.highlighted
                    source: "image://theme/icon-s-warning"
                    color: timestampLabel.color
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    Behavior on showDetails {
        SequentialAnimation {

            // Fade out the simple timestamp, if it isn't hidden and detailed isn't shown
            FadeAnimation {
                duration: 100
                target: timestampRow
                loops: (!hideDefaultTimestamp && !showDetails) ? 1 : 0
                to: 0.0
            }

            // Fade out the detailed timestamp, if it's shown
            FadeAnimation {
                duration: 100
                target: detailedTimestampLoader
                loops: showDetails ? 1 : 0
                to: 0.0
            }

            // This is where showDetails is actually changed, but its value inside this behavior isn't re-evaluated after this
            PropertyAction { }

            // Wait for the height change animation
            PauseAnimation {
                duration: contentHeightAnimation.duration
            }

            // Fade in the detailed timestamp, if it wasn't shown (showDetails isn't re-evaluated here, so we see its past value)
            FadeAnimation {
                duration: 100
                target: detailedTimestampLoader
                loops: !showDetails ? 1 : 0
                from: 0.0
                to: 1.0
            }

            // Fade in the simple timestamp, if it wasn't shown (showDetails isn't re-evaluated here, so we see its past value)
            FadeAnimation {
                duration: 100
                target: timestampRow
                loops: showDetails ? 1 : 0
                to: 1.0
            }
        }
    }

    onClicked: {
        if (canRetry) {
            conversation.message.retryEvent(modelData)
        } else if (eventStatusText.length == 0) {
            showDetails = !showDetails
        }
    }

    states: [
        State {
            name: "outboundErrorNoAttachment"
            when: !inbound && eventStatus >= CommHistory.TemporarilyFailedStatus && attachments.height == 0
            extend: "outboundError"

            PropertyChanges {
                target: retryIcon
                source: "image://theme/icon-m-reload?" + (message.highlighted ? Theme.highlightColor : Theme.primaryColor)
            }
        },
        State {
            name: "outboundError"
            when: !inbound && eventStatus >= CommHistory.TemporarilyFailedStatus
            extend: "error"

            PropertyChanges {
                target: message
                //% "Problem with sending message"
                eventStatusText: qsTrId("messages-send_status_failed")
            }
        },
        State {
            name: "manualReceive"
            when: inbound && eventStatus === CommHistory.ManualNotificationStatus
            extend: "inboundError"

            PropertyChanges {
                target: message
                //% "Tap to download multimedia message"
                eventStatusText: qsTrId("messages-mms_manual_download_prompt")
            }
        },
        State {
            name: "inboundError"
            when: inbound && eventStatus >= CommHistory.TemporarilyFailedStatus
            extend: "error"

            PropertyChanges {
                target: attachmentRetryIcon
                source: "image://theme/icon-m-refresh?" + (message.highlighted ? Theme.highlightColor : Theme.primaryColor)
            }

            PropertyChanges {
                target: message
                //% "Problem with downloading message"
                eventStatusText: qsTrId("messages-receive_status_failed")
            }
        },
        State {
            name: "error"

            PropertyChanges {
                target: message
                canRetry: true
            }

            PropertyChanges {
                target: messageText
                opacity: 1
            }

            PropertyChanges {
                target: timestamp
                opacity: 1
            }

            PropertyChanges {
                target: timestampLabel
                color: message.highlighted ? messageText.color : Theme.primaryColor
            }

            PropertyChanges {
                target: warningIcon
                visible: true
            }
        }
    ]
}

