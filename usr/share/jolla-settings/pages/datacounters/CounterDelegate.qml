import QtQuick 2.0
import Sailfish.Silica 1.0

Column {
    id: root

    property alias title: titleLabel.text
    property var lastResetTime

    property double sent
    property double received

    width: parent.width

    Label {
        id: titleLabel
        color: Theme.highlightColor
        visible: text.length > 0
    }

    Label {
        //% "Sent: %1"
        text: qsTrId("settings_network-la-sent").arg(Format.formatFileSize(sent))
        color: Theme.secondaryHighlightColor
    }

    Label {
        //% "Received: %1"
        text: qsTrId("settings_network-la-received").arg(Format.formatFileSize(received))
        color: Theme.secondaryHighlightColor
    }

    Label {
        //% "Time last cleared: %1"
        text: lastResetTime !== undefined ? qsTrId("settings_network-la-time_last_cleared")
                                            .arg(Format.formatDate(root.lastResetTime, Formatter.Timepoint))
                                          : ""
        color: Theme.secondaryHighlightColor
        wrapMode: Text.WordWrap
        width: parent.width
        visible: text.length > 0
    }
}
