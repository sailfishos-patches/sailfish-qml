import QtQuick 2.0
import Sailfish.Silica 1.0

Column {
    property bool highlighted
    property alias horizontalAlignment: topLabel.horizontalAlignment
    property alias topLabelText: topLabel.text
    property alias bottomLabelText: bottomLabel.text
    property alias ruler: ruler
    property color commonColor: !enabled ? Theme.secondaryHighlightColor
                                         : highlighted  ? Theme.rgba(Theme.highlightColor, 0.5)
                                                        : Theme.secondaryColor
    property color progressColor: !enabled ? Theme.highlightColor
                                           : highlighted ? Theme.highlightColor
                                                         : Theme.primaryColor

    Text {
        id: topLabel
        width: parent.width

        // QTBUG-55873: Workaround for implicitHeight not getting updated
        verticalAlignment: Text.AlignBottom
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: Theme.fontSizeLarge
        color: progressColor
        fontSizeMode: Text.Fit
    }
    Rectangle {
        id: ruler
        width: parent.width
        height: Math.round(2*Theme.pixelRatio)
        color: Theme.rgba(commonColor, Theme.opacityLow)
        x: {
            switch (horizontalAlignment) {
            case Text.AlignHCenter:
                return parent.width/2 - width/2
            case Text.AlignRight:
                return parent.width - width
            default:
                return 0
            }
        }
    }
    Text {
        id: bottomLabel
        width: parent.width
        color: Theme.rgba(commonColor, Theme.opacityHigh)
        font.pixelSize: Theme.fontSizeMedium
        horizontalAlignment: topLabel.horizontalAlignment
        height: topLabel.height // makes vertically centering the ruler within the surrounding circle easier
        fontSizeMode: Text.Fit
    }
}
