// Copyright (C) 2013 Jolla Ltd.
// Contact: Pekka Vuorela <pekka.vuorela@jollamobile.com>

import QtQuick 2.0
import Sailfish.Silica 1.0
import com.meego.maliitquick 1.0

Column {
    id: keyboardLayout

    width: parent ? parent.width : 0

    property string type: model ? model.type : ""
    property bool portraitMode
    property int keyHeight
    property int punctuationKeyWidth
    property int punctuationKeyWidthNarrow
    property int shiftKeyWidth
    property int functionKeyWidth
    property int shiftKeyWidthNarrow
    property int symbolKeyWidthNarrow
    property string languageCode: model ? model.languageCode : ""
    property string inputMode
    property int avoidanceWidth
    property bool splitActive
    property bool splitSupported
    property bool useTopItem: !splitActive
    property bool capsLockSupported: true
    property int layoutIndex: model ? model.index : -1
    property bool allowSwipeGesture: true
    property bool loaderVisible

    property Item handler: {
        var handler = model ? model.handler : ""

        var advancedInputHandler = canvas.layoutModel.inputHandlers[handler]

        if (typeof(advancedInputHandler) === "undefined") {
            console.warn("invalid inputhandler for " + handler + ", forcing paste input handler")
            advancedInputHandler = pasteInputHandler
        }

        if (handler === "") {
            return keyboard.pasteInputHandler
        } else if (type === "") {
            // non-composing
            if (MInputMethodQuick.contentType === Maliit.FreeTextContentType
                    && !MInputMethodQuick.hiddenText
                    && MInputMethodQuick.predictionEnabled) {
                return advancedInputHandler
            } else {
                return keyboard.pasteInputHandler
            }
        } else {
            // composing
            return advancedInputHandler
        }
    }

    property QtObject attributes: QtObject {
        property bool isShifted
        property bool inSymView
        property bool inSymView2
        property bool isShiftLocked
        property bool chineseOverrideForEnter: keyboard.chineseOverrideForEnter
    }

    signal flashLanguageIndicator()

    Component.onCompleted: updateSizes()
    onWidthChanged: updateSizes()
    onPortraitModeChanged: updateSizes()

    Connections {
        target: keyboard
        onSplitEnabledChanged: updateSizes()
    }

    Binding on portraitMode {
        when: MInputMethodQuick.active
        value: keyboard.portraitMode
    }

    Loader {
        // Expose "keyboardLayout" to the context of the loaded TopItem
        readonly property Item keyboardLayout: keyboardLayout

        active: useTopItem && (layoutIndex >= 0)
        // sourceComponent is evaluated even when active is false, so we need the ternary operator here
        sourceComponent: active && keyboardLayout.handler ? keyboardLayout.handler.topItem : null
        width: parent.width
        visible: active
        clip: keyboard.moving
        asynchronous: false
        opacity: (canvas.activeIndex === keyboardLayout.layoutIndex) ? 1.0 : 0.0
        Behavior on opacity { FadeAnimation {}}
    }

    function updateSizes () {
        if (width === 0) {
            return
        }

        if (portraitMode) {
            keyHeight = geometry.keyHeightPortrait
            punctuationKeyWidth = geometry.punctuationKeyPortait
            punctuationKeyWidthNarrow = geometry.punctuationKeyPortraitNarrow
            shiftKeyWidth = geometry.shiftKeyWidthPortrait
            functionKeyWidth = geometry.functionKeyWidthPortrait
            shiftKeyWidthNarrow = geometry.shiftKeyWidthPortraitNarrow
            symbolKeyWidthNarrow = geometry.symbolKeyWidthPortraitNarrow
            avoidanceWidth = 0
            splitActive = false
        } else {
            keyHeight = geometry.keyHeightLandscape
            punctuationKeyWidth = geometry.punctuationKeyLandscape
            punctuationKeyWidthNarrow = geometry.punctuationKeyLandscapeNarrow
            functionKeyWidth = geometry.functionKeyWidthLandscape

            var shouldSplit = keyboard.splitEnabled && splitSupported
            if (shouldSplit) {
                avoidanceWidth = geometry.middleBarWidth
                shiftKeyWidth = geometry.shiftKeyWidthLandscapeSplit
                shiftKeyWidthNarrow = geometry.shiftKeyWidthLandscapeSplit
                symbolKeyWidthNarrow = geometry.symbolKeyWidthLandscapeNarrowSplit
            } else {
                avoidanceWidth = 0
                shiftKeyWidth = geometry.shiftKeyWidthLandscape
                shiftKeyWidthNarrow = geometry.shiftKeyWidthLandscapeNarrow
                symbolKeyWidthNarrow = geometry.symbolKeyWidthLandscapeNarrow
            }
            splitActive = shouldSplit
        }

        var i
        var child
        var maxButton = width

        for (i = 0; i < children.length; ++i) {
            child = children[i]
            child.width = width
            if (child.hasOwnProperty("followRowHeight") && child.followRowHeight) {
                child.height = keyHeight
            }

            if (child.maximumBasicButtonWidth !== undefined && !child.separateButtonSizes) {
                maxButton = Math.min(child.maximumBasicButtonWidth(width), maxButton)
            }
        }

        for (i = 0; i < children.length; ++i) {
            child = children[i]

            if (child.relayout !== undefined) {
                if (child.hasOwnProperty("separateButtonSizes") && child.separateButtonSizes) {
                    var rowMax = child.maximumBasicButtonWidth(width)
                    child.relayout(rowMax)
                } else {
                    child.relayout(maxButton)
                }
            }
        }
    }
}
