import QtQuick 2.6
import Sailfish.Silica 1.0

Item {
    id: root

    property alias title: titleLabel.text
    property alias description: descriptionLabel.text
    property real topPadding: {
        var padding = 2 * Theme.paddingLarge
        if (tight) {
            if (Screen.sizeCategory < Screen.Large) {
                padding = Theme.paddingLarge
            }
        } else if (semiTight) {
            if (_orientation == Qt.LandscapeOrientation || _orientation == Qt.InvertedLandscapeOrientation) {
                padding = Theme.paddingLarge
            }
        }

        return Math.max(padding,
                        _orientation == Qt.PortraitOrientation && Screen.topCutout.height > 0
                        ? Screen.topCutout.height + Theme.paddingSmall : 0)
    }
    property real bottomPadding: Theme.paddingLarge

    property alias titleFont: titleLabel.font
    property alias titleColor: titleLabel.color
    property alias descriptionColor: descriptionLabel.color

    property alias titleTextFormat: titleLabel.textFormat

    property bool tight // save vertical space by smaller padding
    property bool semiTight // save vertical space but not as aggressively as tight

    property Item _systemDialog
    property Item _systemWindow
    property int _orientation: _systemWindow ? _systemWindow.topmostWindowOrientation
                                             : _systemDialog ? _systemDialog.orientation
                                                             : Qt.PortraitOrientation

    height: content.height + topPadding + bottomPadding
    width: (Screen.sizeCategory >= Screen.Large) ? Screen.height / 2 : parent.width
    anchors.horizontalCenter: parent.horizontalCenter

    Component.onCompleted: {
        // this can live either in SystemDialog or SystemWindow, figure out where
        var parentItem = root.parent
        while (parentItem) {
            if (parentItem.hasOwnProperty('__systemDialogAppWindow')) {
                _systemDialog = parentItem
                return
            }
            if (parentItem.hasOwnProperty('topmostWindowOrientation')) {
                _systemWindow = parentItem
                return
            }

            parentItem = parentItem.parent
        }
    }

    Column {
        id: content

        width: parent.width - 2*x
        x: (Screen.sizeCategory < Screen.Large) ? Theme.horizontalPageMargin : 0
        y: root.topPadding
        spacing: Theme.paddingLarge

        Label {
            id: titleLabel

            visible: text !== ""
            width: parent.width
            color: Theme.highlightColor
            font.pixelSize: Theme.fontSizeLarge
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
        }

        Label {
            id: descriptionLabel

            visible: text !== ""
            width: parent.width
            color: Theme.highlightColor
            font.pixelSize: Theme.fontSizeMedium
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
