/****************************************************************************
 **
 ** Copyright (C) 2013-2014 Jolla Ltd.
 ** Contact: Bea Lam <bea.lam@jollamobile.com>
 **
 ****************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0
import com.jolla.lipstick 0.1

NotificationGroupMember {
    id: root

    property QtObject notification
    property string summaryText
    property string bodyText
    property string timestampText

    property bool animateContentResizing
    property bool summaryOnly: notification && notification.maxContentLines == 1
    property bool showItemCount: notification && notification.itemCount > 1 && summaryOnly

    // Only show the first line of the summary, if there is more
    property string _summaryLine: _nthLine(summaryText, 0)

    property real _iconBottom: _displayAvatar ? originAvatar.y + originAvatar.height : 0
    property bool _displayAvatar: notification && notification.origin.substr(0, 7) == "avatar:"
    property bool _displayBody: !summaryOnly && bodyText.length && _summaryLine.length
    property int _maxBodyLines: notification ? Math.min(notification.maxContentLines > 0 ? notification.maxContentLines - 1 : 2, 5) : 1
    property bool hasProgress: notification && notification.hasProgress
    property real progress: notification ? notification.progress : 0

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

    contentHeight: Math.max(contentColumn.y + contentColumn.height, _iconBottom) + Theme.paddingMedium
    deleteIconCenterY: originAvatar.y + originAvatar.height/2

    Column {
        id: contentColumn

        y: Theme.paddingMedium
        anchors {
            left: _displayAvatar ? originAvatar.right : parent.left
            leftMargin: _displayAvatar ? Theme.paddingMedium : 0
            right: parent.right
        }

        Item {
            height: summary.height
            width: parent.width

            Label {
                id: summary

                // If the full width does not fit, truncate so that the timestamp remains visible
                width: Math.min(implicitWidth, parent.width - timestamp.paddedWidth - itemCount.paddedWidth)
                // If there is no summary, fallback to show the first part of the body
                text: _summaryLine.length ? _summaryLine : _nthLine(bodyText, 0)
                textFormat: Text.PlainText
                maximumLineCount: 1
                truncationMode: TruncationMode.Fade
                font.pixelSize: Theme.fontSizeMedium
                color: root.highlighted ? Theme.highlightColor : Theme.primaryColor

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

                property real paddedWidth: visible ? width + Theme.paddingSmall : 0

                anchors {
                    baseline: summary.baseline
                    left: summary.right
                    leftMargin: Theme.paddingSmall
                }
                visible: showItemCount
                text: notification ? '(' + notification.itemCount + ')' : 0
                font.pixelSize: Theme.fontSizeMedium
                color: root.highlighted ? Theme.highlightColor : Theme.primaryColor
            }

            Label {
                id: timestamp

                property real paddedWidth: width + Theme.paddingLarge

                anchors {
                    baseline: summary.baseline
                    left: itemCount.visible ? itemCount.right : summary.right
                    leftMargin: Theme.paddingLarge
                }
                text: root.timestampText
                font.pixelSize: Theme.fontSizeExtraSmall
                color: root.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
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
            wrapMode: Text.WordWrap
            maximumLineCount: _maxBodyLines
            truncationMode: TruncationMode.Elide
            font.pixelSize: Theme.fontSizeExtraSmall
            color: root.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
        }
    }

    // FIXME: this should use some image/icon type of property, plenty to choose from.
    Image {
        id: originAvatar

        y: Theme.paddingMedium
        visible: _displayAvatar
        source: notification ? notification.origin.substr(7) : ""
        width: Theme.iconSizeMedium
        height: width
    }
}
