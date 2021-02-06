/****************************************************************************
 **
 ** Copyright (C) 2013 - 2019 Jolla Ltd.
 ** Copyright (C) 2020 Open Mobile Platform LLC.
 **
 ****************************************************************************/

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0
import com.jolla.lipstick 0.1
import org.nemomobile.lipstick 0.1

NotificationGroupMember {
    id: root

    property QtObject notification
    property string summaryText
    property string bodyText
    property string timestampText

    property bool animateContentResizing
    property bool summaryOnly: bodyText.length === 0
    property bool showItemCount: notification && notification.itemCount > 1
    property bool hasExpandableContent: actionRow.visibleCount > 0 && !Lipstick.compositor.lockScreenLayer.lockScreenEventsEnabled // TODO: also check if long body text
    property bool expanded

    // Only show the first line of the summary, if there is more
    property string _summaryLine: _nthLine(summaryText, 0)

    property real _iconBottom: notificationIcon.loaded ? notificationIcon.height + 2*notificationIcon.y : 0
    readonly property bool _displayBody: bodyText.length && _summaryLine.length
    readonly property int _maxBodyLines: expanded ? 25 : 5
    property bool hasProgress: notification && notification.hasProgress
    property real progress: notification ? notification.progress : 0

    signal expand

    onHousekeepingChanged: expanded = false

    function _nthLine(str, n) {
        var start = 0
        var end = -1
        while (n >= 0) {
            start = end + 1
            end = str.indexOf("\n", start)
            --n
            if ((end == -1) && (n >= 0)) {
                return ""
            }
        }
        if (end > start) {
            return str.substr(start, (end - start))
        }
        return str.substr(start)
    }

    contentHeight: Math.max(2 * contentColumn.y + contentColumn.height, _iconBottom)
    draggable: housekeeping && userRemovable

    VerticalAutoScroll.keepVisible: expanded && (actionRow.animating || bodyHeightAnimation.running)
    VerticalAutoScroll.topMargin: Theme.paddingLarge
    VerticalAutoScroll.bottomMargin: Theme.paddingLarge

    Column {
        id: contentColumn

        y: Theme.paddingMedium
        anchors {
            left: notificationIcon.loaded ? notificationIcon.right : parent.left
            leftMargin: notificationIcon.loaded ? Theme.paddingMedium : 0
            right: parent.right
        }

        Item {
            height: summary.height
            width: parent.width
            Label {
                id: summary

                // If the full width does not fit, truncate so that the timestamp remains visible
                width: Math.min(implicitWidth, availableWidth)
                property int availableWidth: parent.width - timestamp.paddedWidth - itemCount.paddedWidth - expandButton.paddedWidth

                // If there is no summary, fallback to show the first part of the body
                text: _summaryLine.length ? _summaryLine : _nthLine(bodyText, 0)
                textFormat: Text.PlainText
                maximumLineCount: 1
                truncationMode: TruncationMode.Fade

                Behavior on width {
                    enabled: root.animateContentResizing
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.InOutQuad
                    }
                }
            }

            Label {
                id: itemCount

                property real paddedWidth: showItemCount ? width + Theme.paddingSmall : 0

                anchors {
                    baseline: summary.baseline
                    left: summary.right
                    leftMargin: Theme.paddingSmall
                }
                visible: showItemCount
                text: notification ? '(' + notification.itemCount + ')' : 0
                font.pixelSize: Theme.fontSizeMedium
            }

            Label {
                id: timestamp

                property real paddedWidth: width + Theme.paddingMedium

                anchors {
                    baseline: summary.baseline
                    left: itemCount.visible ? itemCount.right : summary.right
                    leftMargin: Theme.paddingMedium
                }

                text: root.timestampText
                font.pixelSize: Theme.fontSizeExtraSmall
                color: root.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
            }

            IconButton {
                id: expandButton

                property real paddedWidth: enabled ? icon.width + Theme.paddingLarge : 0

                icon {
                    transformOrigin: Item.Center
                    source: "image://theme/icon-s-arrow"
                    rotation: expanded ? 180 : 0
                }
                Behavior on icon.rotation { RotationAnimator { duration: 200 }}

                onClicked: {
                    if (expanded) {
                        expanded = false
                    } else {
                        expand()
                    }
                }

                enabled: !housekeeping && ((!expanded && hasExpandableContent) || (expanded && userRemovable))
                opacity: enabled ? 1.0 : 0.0
                Behavior on opacity { FadeAnimator {}}
                height: Math.max(parent.height, Theme.itemSizeSmall)
                width: icon.width + 2*Theme.paddingLarge
                anchors {
                    verticalCenter: summary.verticalCenter
                    right: parent.right
                    // a little over the edge to increase the reactive area
                    rightMargin: -Theme.paddingLarge
                }
            }
        }

        Loader {
            active: progressLatch.value
            sourceComponent: Component {
                ProgressBar {
                    id: progressBar

                    value: root.progress
                    width: contentColumn.width
                    opacity: root.hasProgress ? 1.0 : 0.0
                    visible: opacity > 0
                    indeterminate: root.progress < 0
                    height: opacity * implicitHeight
                    leftMargin: Theme.paddingSmall
                    rightMargin: Theme.paddingSmall
                    highlighted: root.highlighted

                    // avoid changing value during hiding
                    Binding {
                        target: progressBar
                        property: "value"
                        value: root.progress
                        when: root.hasProgress
                    }

                    Behavior on opacity { FadeAnimation {} }
                }
            }

            Latch {
                id: progressLatch
                value: root.hasProgress
            }
        }

        Label {
            id: body

            width: parent.width
            visible: _displayBody && _maxBodyLines > 0
            text: bodyText
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            maximumLineCount: _maxBodyLines
            truncationMode: TruncationMode.Elide
            font.pixelSize: Theme.fontSizeExtraSmall

            height: implicitHeight
            Behavior on height {
                NumberAnimation {
                    id: bodyHeightAnimation
                    easing.type: Easing.InOutQuad
                    duration: 200
                }
            }
        }

        Item { width: 1; height: Theme.paddingMedium }

        NotificationActionRow {
            id: actionRow
            active: expanded
            onActionInvoked: notification.actionInvoked(actionName)
            anchors.right: parent.right
        }
    }

    NotificationIcon {
        id: notificationIcon
        y: Theme.paddingMedium
    }
}
