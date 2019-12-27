import QtQuick 2.0
import Sailfish.Silica 1.0

BackgroundItem {
    id: root
    property string text
    property url link

    property real leftMargin
    property real rightMargin

    property bool _disabled
    property bool _applicationActive: Qt.application.active
    on_ApplicationActiveChanged: {
        if (_applicationActive && _disabled) {
            _disabled = false
        }
    }

    enabled: link != '' && !_disabled
    opacity: enabled ? 1.0 : Theme.opacityLow

    onClicked: {
        // Disable to prevent extra clicking while the browser loads
        _disabled = true
        Qt.openUrlExternally(link)
    }

    Text {
        x: root.leftMargin
        width: root.width - x - root.rightMargin

        color: Theme.highlightColor
        font { pixelSize: Theme.fontSizeMedium }
        wrapMode: Text.Wrap
        textFormat: Text.StyledText
        text: '<u>' + root.text + '</u>'
    }
}
