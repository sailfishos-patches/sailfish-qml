/*
 * Copyright (c) 2015 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    property int horizontalMargin: (Screen.sizeCategory >= Screen.Large ? 133 : 25) * xScale
    property int verticalMargin: (Screen.sizeCategory >= Screen.Large ? 195 : 75) * yScale
    property alias horizontalSpacing: grid.columnSpacing
    property alias verticalSpacing: grid.rowSpacing

    Grid {
        id: grid

        anchors {
            top: parent.top
            topMargin: verticalMargin
            bottom: parent.bottom
            bottomMargin: verticalMargin
            left: parent.left
            leftMargin: horizontalMargin
            right: parent.right
            rightMargin: horizontalMargin
        }

        columnSpacing: (Screen.sizeCategory >= Screen.Large ? 107 : 21) * xScale
        rowSpacing: (Screen.sizeCategory >= Screen.Large ? 107 : 21) * yScale

        rows: 2
        columns: 3

        Repeater {
            model: Screen.sizeCategory >= Screen.Large
                   ? ["people", "clock", "camera", "settings", "browser", "gallery"]
                   : ["people", "clock", "store", "settings", "browser", "gallery"]

            Image {
                width: {
                    if (Screen.width > 1080) {
                        352 * xScale
                    } else if (Screen.height <= 2519) {
                        136 * xScale
                    }
                }
                height: {
                    if (Screen.width > 1080) {
                        562 * yScale
                    } else if (Screen.height <= 2519) {
                        218 * yScale
                    }
                }
                fillMode: Screen.sizeCategory >= Screen.Large ? null : Image.PreserveAspectCrop

                source: Screen.sizeCategory >= Screen.Large
                        ? Qt.resolvedUrl("file:///usr/share/sailfish-tutorial/graphics/tutorial-tablet-" + modelData + "-cover.png")
                        : Qt.resolvedUrl("file:///usr/share/sailfish-tutorial/graphics/tutorial-phone-" + modelData + "-cover.png")
            }
        }
    }
}
