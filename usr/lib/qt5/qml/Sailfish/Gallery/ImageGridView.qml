import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0 as Private

SilicaGridView {
    id: grid

    property real cellSize: Math.floor(width / columnCount)
    property int columnCount: Math.floor(width / Theme.itemSizeHuge)
    property int maxContentY: Math.max(0, contentHeight - height) + originY
    property string dateProperty: "dateTaken"

    // QTBUG-95676: StopAtBounds does not work with StrictlyEnforceRange,
    // work-around by implementing StopAtBounds locally
    onContentYChanged: if (contentY > maxContentY) contentY = maxContentY

    preferredHighlightBegin: 0
    preferredHighlightEnd: headerItem.height + cellSize
    highlightRangeMode: GridView.StrictlyEnforceRange

    quickScroll: false
    cacheBuffer: 1000
    cellWidth: cellSize
    cellHeight: cellSize

    // Make header visible if it exists.
    Component.onCompleted: if (header) grid.positionViewAtBeginning()

    maximumFlickVelocity: 5000*Theme.pixelRatio

    Private.Scrollbar {
        property var date: {
            if (grid.model) {

                // Disable on Gallery albums that don't use QtDocGallery
                if (typeof grid.model.get === "undefined") {
                    visible = false
                    return undefined
                }

                var item = grid.model.get(grid.currentIndex)
                if (item) {
                    return item[dateProperty]
                }
            }
            return undefined
        }

        text: date ? Format.formatDate(date, Format.MonthNameStandalone) : ""
        description: date ? date.getFullYear() : ""
        headerHeight: grid.headerItem ? grid.headerItem.height : 0
        stepSize: grid.cellHeight
    }
}
