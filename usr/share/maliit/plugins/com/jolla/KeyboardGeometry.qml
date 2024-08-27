// Copyright (C) 2013 Jolla Ltd.
// Contact: Pekka Vuorela <pekka.vuorela@jollamobile.com>

import QtQuick 2.0
import Sailfish.Silica 1.0

QtObject {
    // FIXME: need different scale ratio for landscape in case aspect ratio changes, now assuming 16:9
    property bool isLargeScreen: screen.sizeCategory > Screen.Medium
    property real scaleRatio: isLargeScreen ? screen.width / 580 : screen.width / 480
    property real verticalScale: isLargeScreen ? screen.width / 768 : scaleRatio

    // extra paddings horizontally or vertically to avoid overlapping rounded corners
    // using the biggest to keep symmetry
    property int cornerPadding: {
        // assuming the roundings are simple with x and y detached the radius amount from edges.
        var biggestCorner = Math.max(Screen.topLeftCorner.radius,
                                     Screen.topRightCorner.radius,
                                     Screen.bottomLeftCorner.radius,
                                     Screen.bottomRightCorner.radius)
        // 0.7 assumed being enough of the rounding to avoid
        return biggestCorner * 0.7
    }

    property int keyboardWidthLandscape: {
        var avoidance = Math.max(Screen.topCutout.height, cornerPadding)
        // avoiding in both sides to keep symmetry
        return screen.height - (avoidance * 2)
    }
    property int keyboardWidthPortrait: screen.width

    property int keyHeightLandscape: isLargeScreen ? keyHeightPortrait : 58*verticalScale
    property int keyHeightPortrait: 80*verticalScale
    property int keyRadius: 4*scaleRatio

    property int functionKeyWidthLandscape: 145*scaleRatio
    property int shiftKeyWidthLandscape: 110*scaleRatio
    property int shiftKeyWidthLandscapeNarrow: 98*scaleRatio
    property int shiftKeyWidthLandscapeSplit: 77*scaleRatio
    property int punctuationKeyLandscape: 80*scaleRatio
    property int symbolKeyWidthLandscapeNarrow: functionKeyWidthLandscape
    property int symbolKeyWidthLandscapeNarrowSplit: 100*scaleRatio

    property int functionKeyWidthPortrait: 95*scaleRatio
    property int shiftKeyWidthPortrait: 72*scaleRatio
    property int shiftKeyWidthPortraitNarrow: 60*scaleRatio
    property int punctuationKeyPortait: 43*scaleRatio
    property int symbolKeyWidthPortraitNarrow: functionKeyWidthPortrait

    property int middleBarWidth: keyboardWidthLandscape / 4

    property int popperHeight: isLargeScreen ? 99*scaleRatio : 120*scaleRatio
    property int popperWidth: isLargeScreen ? 66*scaleRatio : 80*scaleRatio
    property int popperRadius: 10*scaleRatio
    property int popperFontSize: 56*scaleRatio
    property int popperMargin: 2

    property int clearPasteMargin: 50*scaleRatio
    property int clearPasteTouchDelta: 20*scaleRatio

    property int accentPopperCellWidth: 47*scaleRatio
    property int accentPopperMargin: (popperWidth-accentPopperCellWidth) * .5 - 1

    property int languageSelectionTouchDelta: isLargeScreen ? 20*scaleRatio : 35*scaleRatio
    property int languageSelectionInitialDeltaSquared: 20*20*scaleRatio
    property int languageSelectionCellMargin: 15*scaleRatio
    property int languageSelectionPopupMaxWidth: isLargeScreen ? screen.width * .8 : screen.height * .75
    property int languageSelectionPopupContentMargins: 40*scaleRatio

    property int hwrLineWidth: 7*Theme.pixelRatio
    property int hwrCanvasHeight: isLargeScreen ? 240*scaleRatio : 300*scaleRatio
    property int hwrSampleThresholdSquared: 4*4*scaleRatio
    property int hwrPastePreviewWidth: 100*scaleRatio
}
