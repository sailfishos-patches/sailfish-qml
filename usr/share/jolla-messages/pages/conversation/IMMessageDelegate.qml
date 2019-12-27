import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.TextLinking 1.0
import org.nemomobile.commhistory 1.0

ListItem {
    id: message

    property QtObject modelData
    property bool inbound: modelData !== null ? (modelData.direction === CommHistory.Inbound) : false
    property bool canRetry
    property bool hasText: true
    property int eventStatus

    menu: messageContextMenu

    contentHeight: __silica_remorse_item ? Theme.itemSizeSmall
                                         : Math.max(retryIcon.height, textLabel.implicitHeight + errorLabel.height) + Theme.paddingSmall
    Behavior on contentHeight {
        NumberAnimation {
            duration: 200
            easing.type: Easing.InOutQuad
        }
    }

    Image {
        id: retryIcon
        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
            rightMargin: Theme.horizontalPageMargin
        }
    }

    Label {
        id: timeLabel
        width: Math.max(paintedWidth + Theme.horizontalPageMargin, Theme.itemSizeSmall)
        anchors.baseline: textLabel.baseline
        horizontalAlignment: Text.AlignRight

        font.pixelSize: Theme.fontSizeExtraSmall
        text: modelData ? Format.formatDate(modelData.startTime, Formatter.TimeValue) : ""
        color: (!inbound || message.highlighted) ? Theme.highlightColor : Theme.primaryColor
        opacity: textLabel.opacity - Theme.opacityFaint
    }

    LinkedText {
        id: textLabel
        y: Theme.paddingSmall / 2
        anchors {
            left: timeLabel.right
            leftMargin: Theme.paddingMedium
            right: parent.right
            rightMargin: Theme.horizontalPageMargin
        }

        font.pixelSize: Theme.fontSizeSmall
        wrapMode: Text.Wrap
        plainText: modelData ? modelData.freeText : ""
        color: timeLabel.color
        linkColor: inbound || message.highlighted ? Theme.highlightColor : Theme.primaryColor
        opacity: (inbound || message.highlighted) ? 1 : Theme.opacityOverlay
    }

    Label {
        id: errorLabel
        height: visible ? implicitHeight : 0
        anchors {
            left: textLabel.left
            right: retryIcon.left
            top: textLabel.bottom
            rightMargin: Theme.paddingMedium
        }
        wrapMode: Text.Wrap

        visible: false
        font.pixelSize: Theme.fontSizeTiny
    }

    onClicked: {
        if (state !== "error")
            return

        conversation.message.retryEvent(modelData)
    }

    states: State {
        name: "error"
        when: eventStatus >= CommHistory.TemporarilyFailedStatus

        PropertyChanges {
            target: message
            canRetry: true
        }

        PropertyChanges {
            target: retryIcon
            source: "image://theme/icon-m-reload?" + (message.highlighted ? Theme.highlightColor : Theme.primaryColor)
        }

        PropertyChanges {
            target: timeLabel
            visible: false
        }

        PropertyChanges {
            target: textLabel
            opacity: 1
        }

        PropertyChanges {
            target: errorLabel
            visible: true
            //% "Problem with sending message"
            text: qsTrId("messages-send_status_failed")
            color: message.highlighted ? Theme.highlightColor : Theme.primaryColor
        }
    }
}

