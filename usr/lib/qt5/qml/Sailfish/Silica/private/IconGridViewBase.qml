import QtQuick 2.4
import Sailfish.Silica 1.0
import "Util.js" as Util
import Nemo.Configuration 1.0

SilicaGridView {
    id: root

    property int pageHeight: height
    property int horizontalMargin: {
        var margin = configs.launcher_horizontal_margin
        if (margin) {
            return margin
        } else {
            return Math.max((!isPortrait && Screen.topCutout.height > 0)
                            ? (Screen.topCutout.height + Theme.paddingSmall) : 0,
                            largeScreen ? (fullHdPortraitWidth ? 3 : 6) * Theme.paddingLarge
                                        : (Theme.paddingLarge + Theme.paddingSmall))
        }
    }
    property int launcherItemSpacing: Theme.paddingSmall
    property real minimumDelegateSize: Theme.iconSizeLauncher
    property bool isPortrait: orientation === Orientation.Portrait
                              || orientation === Orientation.PortraitInverted
    property int orientation: _page ? _page.orientation : Orientation.Portrait
    property Item _page: Util.findPage(root)

    // For wider than 16:9 full hd
    // FIXME: See Bug #43014
    readonly property bool fullHdPortraitWidth: Screen.width == 1080

    // The multipliers below for Large screens are magic. They look good on Jolla tablet.
    property real minimumCellWidth: largeScreen ? (fullHdPortraitWidth ? 1.2 : 1.6) * Theme.itemSizeExtraLarge
                                                  // leave room for launcher icon and paddings
                                                : Theme.iconSizeLauncher + Theme.paddingLarge + Theme.paddingMedium
    // phone reference row height: 960 / 6
    property real minimumCellHeight: largeScreen ? (fullHdPortraitWidth ? 1.2 : 1.6) * Theme.itemSizeExtraLarge
                                                   // leave room for launcher icon, app title, spacing between, and paddings around
                                                 : Theme.iconSizeLauncher + Theme.paddingLarge + Theme.paddingMedium
                                                   + launcherLabelMetrics.height + launcherItemSpacing

    property alias launcherLabelFontSize: launcherLabelMetrics.font.pixelSize
    property int rows: {
        var rows = isPortrait ? configs.launcher_rows_portrait
                              : configs.launcher_rows_landscape

        if (rows > 0) {
            return rows
        } else {
            return Math.max(isPortrait ? 6 : 3, Math.floor(pageHeight / minimumCellHeight))
        }
    }

    property int columns: {
        var columns = isPortrait ? configs.launcher_columns_portrait
                                 : configs.launcher_columns_landscape
        if (columns > 0) {
            return columns
        } else {
            return Math.max(isPortrait ? 4 : 6, Math.floor(parent.width / minimumCellWidth))
        }
    }

    property int initialCellWidth: (parent.width - 2*horizontalMargin) / columns
    readonly property bool largeScreen: Screen.sizeCategory >= Screen.Large

    cellWidth: Math.floor(initialCellWidth + (initialCellWidth - minimumDelegateSize) / (columns - 1))
    cellHeight: Math.round(pageHeight / rows)

    width: cellWidth * columns
    anchors.horizontalCenter: parent.horizontalCenter

    FontMetrics {
        id: launcherLabelMetrics
        font.pixelSize: Theme.fontSizeTiny
    }

    ConfigurationGroup {
        id: configs

        path: "/desktop/sailfish/experimental"
        property int launcher_horizontal_margin
        property int launcher_rows_portrait
        property int launcher_rows_landscape
        property int launcher_columns_portrait
        property int launcher_columns_landscape
    }
}
