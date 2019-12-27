// Copyright (C) 2013 Jolla Ltd.
// Contact: Pekka Vuorela <pekka.vuorela@jollamobile.com>

import QtQuick 2.6
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0
import com.jolla.keyboard 1.0

Item {
    id: layoutRow

    property int nextActiveIndex: -1
    property alias previousLayout: previousLayoutConfig.value
    property Item layout: _loader1.item
    property LayoutLoader loader: _loader1
    property LayoutLoader nextLoader: null
    property bool loading: _loader1.status === Loader.Loading || _loader2.status === Loader.Loading || _loader3.status === Loader.Loading || _loader4.status === Loader.Loading
    property real swipeSwitchGestureThreshold: switchTransitionPadding * 2
    property var layoutTransition: null
    property bool transitionRunning: _manualTransition || (layoutTransition && layoutTransition.running)
    property real switchTransitionPadding: Theme.paddingLarge * 3
    property bool _transitionFromLeft
    property bool _manualTransition
    property var _loaders: [_loader1, _loader2, _loader3, _loader4]

    width: parent.width

    LayoutLoader {
        id: _loader1
        index: canvas.activeIndex
        onIndexChanged: index = index // remove binding
    }

    LayoutLoader {
        id: _loader2
        index: ((canvas.activeIndex !== -1) && (canvas.layoutModel.enabledCount > 1)) ? keyboard.getLeftAdjacentLayoutIndex(canvas.activeIndex) : -1
        onIndexChanged: index = index // remove binding
        visible: false
    }

    LayoutLoader {
        id: _loader3
        index: ((canvas.activeIndex !== -1) && (canvas.layoutModel.enabledCount > 2)) ? keyboard.getRightAdjacentLayoutIndex(canvas.activeIndex) : -1
        onIndexChanged: index = index // remove binding
        visible: false
    }

    LayoutLoader {
        id: _loader4
        visible: false
    }

    // NOTE: This being in a Component is a workaround to a nasty XAnimator crash. For more details, see JB#43093.
    Component {
        id: layoutTransitionComponent

        SequentialAnimation {
            ParallelAnimation {
                XAnimator {
                    duration: 200
                    target: layoutRow.layout
                    from: target ? target.x : 0
                    to: transitionOutLayoutX()
                    easing.type: Easing.InOutQuad
                }
                XAnimator {
                    duration: 200
                    target: currentLayoutBackground
                    from: target ? target.x : 0
                    to: transitionOutLayoutX() - switchTransitionPadding / 2
                    easing.type: Easing.InOutQuad
                }

                XAnimator {
                    duration: 200
                    target: layoutRow.nextLoader && layoutRow.nextLoader.item
                    from: target ? target.x : 0
                    to: 0
                    easing.type: Easing.InOutQuad
                }
                XAnimator {
                    duration: 200
                    target: newLayoutBackground
                    from: target ? target.x : 0
                    to: -switchTransitionPadding / 2
                    easing.type: Easing.InOutQuad
                }
            }
            ScriptAction {
                script: {
                    layoutRow.finalizeTransition()
                    canvas.saveCurrentLayoutSetting()

                    // Destroy transition and prevent access to destroyed object
                    layoutTransition.destroy()
                    layoutTransition = null
                }
            }
        }
    }

    Component {
        id: cancelLayoutTransitionComponent

        SequentialAnimation {
            ParallelAnimation {
                XAnimator {
                    duration: 200
                    target: layoutRow.layout
                    from: target.x
                    to: 0
                    easing.type: Easing.InOutQuad
                }
                XAnimator {
                    duration: 200
                    target: currentLayoutBackground
                    from: target.x
                    to: -switchTransitionPadding / 2
                    easing.type: Easing.InOutQuad
                }

                XAnimator {
                    duration: 200
                    target: layoutRow.nextLoader ? layoutRow.nextLoader.item : null
                    from: target ? target.x : 0
                    to: -transitionOutLayoutX()
                    easing.type: Easing.InOutQuad
                }
                XAnimator {
                    duration: 200
                    target: newLayoutBackground
                    from: target ? target.x : 0
                    to: -transitionOutLayoutX() - switchTransitionPadding / 2
                    easing.type: Easing.InOutQuad
                }
            }
            ScriptAction {
                script: {
                    layoutRow.nextLoader.visible = false

                    // Destroy transition and prevent access to destroyed object
                    layoutTransition.destroy()
                    layoutTransition = null
                }
            }
        }
    }

    function transitionOutLayoutX() {
        // When the user swipes right, old layout goes from left to right, outside of the screen
        var targetX = keyboard.width + switchTransitionPadding

        // When the user swipes left, invert
        if (!_transitionFromLeft) {
            targetX = -targetX
        }

        return targetX
    }

    function switchLayout(layoutIndex, manual) {
        if (transitionRunning) {
            // A transition is still running, initiating another switch would bork the layout
            return
        }

        if (_manualTransition && nextActiveIndex === layoutIndex) {
            // Manual transition already started (ie. new layout is already loading)
            return
        }

        if (layoutIndex >= 0 && layoutIndex !== canvas.activeIndex) {
            _manualTransition = !!manual
            updateTransitionDirection(layoutIndex)

            if (nextLoader.status === Loader.Ready) {
                startTransition()
            } else {
                nextLoader.loaded.connect(function onLoaded() {
                    nextLoader.loaded.disconnect(onLoaded)
                    startTransition()
                })
            }
        }
    }

    function updateTransitionDirection(layoutIndex) {
        if (nextLoader !== null) {
            nextLoader.visible = false
        }

        nextActiveIndex = layoutIndex
        var nextLayoutIsAdjacent = true

        var leftIndex = keyboard.getLeftAdjacentLayoutIndex()
        var rightIndex = keyboard.getRightAdjacentLayoutIndex()

        // Decide transition direction
        if (canvas.layoutModel.enabledCount === 2) {
            _transitionFromLeft = _manualTransition && keyboard.direction === SwipeGestureArea.DirectionRight
        } else if (nextActiveIndex === rightIndex) {
            _transitionFromLeft = false
        } else if (nextActiveIndex === leftIndex) {
            _transitionFromLeft = true
        } else {
            _transitionFromLeft = (nextActiveIndex < canvas.activeIndex)
            nextLayoutIsAdjacent = false
        }

        // Decide which layouts need to be loaded
        if (nextLayoutIsAdjacent) {
            // If the next layout is adjacent:
            // We need the current layout and its neighbours (one of which is what we switch to),
            // and the new neighbour which depends on direction.

            var newNeighbourIndex
            if (_transitionFromLeft) {
                newNeighbourIndex = keyboard.getLeftAdjacentLayoutIndex(layoutIndex)
            } else {
                newNeighbourIndex = keyboard.getRightAdjacentLayoutIndex(layoutIndex)
            }

            updateLoaders([canvas.activeIndex, leftIndex, rightIndex, newNeighbourIndex])
        } else {
            // If the next layout is non-adjacent:
            // We need the current and next layout (obviously) and the neighbours of the
            // new layout.

            var newLeftIndex = keyboard.getLeftAdjacentLayoutIndex(layoutIndex)
            var newRightIndex = keyboard.getRightAdjacentLayoutIndex(layoutIndex)

            updateLoaders([canvas.activeIndex, layoutIndex, newLeftIndex , newRightIndex])
        }

        var nextLoaderIndex = findLoaderIndexForLayoutIndex(layoutIndex)
        if (nextLoaderIndex === -1) {
            console.warn("updateTransitionDirection: couldn't find nextLoader, this is a bug!")
            return
        }

        nextLoader = _loaders[nextLoaderIndex]
        nextLoader.visible = false
        nextLoader.index = layoutIndex

        // NOTE: nextLoader.item should be already loaded at this point,
        //       but there are edge cases when it isn't, so play it safe.
        if (nextLoader.item) {
            nextLoader.item.y = layoutRow.layout.height - nextLoader.item.height
        } else {
            nextLoader.loaded.connect(function onNextLoaderLoaded() {
                nextLoader.loaded.disconnect(onNextLoaderLoaded)
                nextLoader.item.y = layoutRow.layout.height - nextLoader.item.height
            })
        }
    }

    function findLoaderIndexForLayoutIndex(layoutIndex) {
        for (var i = 0; i < _loaders.length; i++) {
            if (_loaders[i].index === layoutIndex) {
                return i
            }
        }

        return -1
    }

    function updateLoaders(requestedIndexes) {
        // This function is used to ensure that a given set of layouts are loaded.
        // The main goal of this function is to make the layout switch transition
        // smooth by reusing already loaded layouts.

        if (requestedIndexes.length > _loaders.length) {
            console.warn("updateLoaders: not enough loaders (got", loaders.length, ") to fit requested indexes (got", requestedIndexes.length, "). This is a bug.")
            return
        }

        // Put available loaders into a JS array.
        var availableLoaders = _loaders.slice()

        // Will hold non-loaded layout indexes that we'll need to load.
        var nonLoadedIndexes = []

        // Go through all requested layout indexes
        for (var i = 0; i < requestedIndexes.length; i++) {
            // Try to find a loader that already contains this layout
            var loaderIndex = findLoaderIndexForLayoutIndex(requestedIndexes[i])

            // If not found, save it to the list of non-loaded layouts
            if (loaderIndex === -1) {
                // Also check if we already saved it to the non-loaded indexes array
                var nonLoadedIndex = nonLoadedIndexes.indexOf(requestedIndexes[i])
                if (nonLoadedIndex === -1) {
                    nonLoadedIndexes.push(requestedIndexes[i])
                }
                continue
            }

            // Remove the found loader from the list of available loaders, if it contains it
            var spliceIndex = availableLoaders.indexOf(_loaders[loaderIndex])
            if (spliceIndex >= 0) {
                availableLoaders.splice(spliceIndex, 1)
            }
        }



        // Go through all layouts that are not loaded yet, and pick an available loader for them to load
        for (i = 0; i < nonLoadedIndexes.length; i++) {
            var availableLoader = availableLoaders.splice(0, 1)[0]
            availableLoader.index = nonLoadedIndexes[i]
        }

        // Go through all remaining available loaders and unload their content
        for (i = 0; i < availableLoaders.length; i++) {
            availableLoaders[i].index = -1
        }
    }

    function updateLoadersToLayoutAndNeighbours(layoutIndex) {
        // Update loaders to a given layout and its neighbours, and unload the rest
        var left = keyboard.getLeftAdjacentLayoutIndex(layoutIndex)
        var right = keyboard.getRightAdjacentLayoutIndex(layoutIndex)

        updateLoaders([layoutIndex, left, right])
    }

    function switchToPreviousCharacterLayout() {
        if (previousLayout.length > 0) {
            for (var index = 0; index < canvas.layoutModel.count; index++) {
                var layout = canvas.layoutModel.get(index)
                if (layout.enabled && layout.layout === previousLayout) {
                    switchLayout(index)
                    return
                }
            }
        }

        for (index = 0; index < canvas.layoutModel.count; index++) {
            layout = canvas.layoutModel.get(index)
            if (layout.enabled && layout.type !== "emojis") {
                switchLayout(index)
                return
            }
        }
    }

    function startTransition() {
        if (nextActiveIndex >= 0) {
            if (nextLoader.status !== Loader.Ready) {
                // Note that startTransition is called from the onLoaded handler of the nextLoader, so we should always assume that
                // it is Ready when startTransition is called. May happen when status is Error for example.
                console.warn("startTransition: called while nextLoader.status not Ready")
                return
            }

            // State of the next layout should be independent from the state of the current one
            keyboard.nextLayoutAttributes.update(nextLoader.item)
            nextLoader.item.attributes = keyboard.nextLayoutAttributes

            nextLoader.item.updateSizes()
            nextLoader.visible = true

            if (!MInputMethodQuick.active) {
                nextLoader.item.x = 0
                finalizeTransition()
            } else {
                nextLoader.item.y = layoutRow.layout.height - nextLoader.item.height

                if (_transitionFromLeft) {
                    nextLoader.item.x = layoutRow.layout.x - nextLoader.item.width - switchTransitionPadding

                } else {
                    nextLoader.item.x = layoutRow.layout.x + layoutRow.layout.width + switchTransitionPadding
                }

                if (!_manualTransition) {
                    layoutTransition = layoutTransitionComponent.createObject(layoutRow)
                    layoutTransition.start()
                }
            }
        }
    }

    function updateManualTransition(swipeAmount) {
        if (!_manualTransition) {
            return
        }

        layoutRow.layout.x = swipeAmount

        if (nextLoader !== null && nextLoader.status === Loader.Ready) {
            // Make sure loader is always visible
            nextLoader.visible = true

            // Update new layout position
            if (keyboard.direction === SwipeGestureArea.DirectionLeft) {
                nextLoader.item.x = layoutRow.layout.x + layoutRow.layout.width + switchTransitionPadding
            } else {
                nextLoader.item.x = layoutRow.layout.x - nextLoader.item.width - switchTransitionPadding
            }
        }
    }

    function endManualTransition() {
        if (!_manualTransition || !nextLoader) {
            // Already cancelled, or the gesture is already completed
            return
        }

        var swipeAmount = layoutRow.layout.x
        var swipeAmountAbs = Math.abs(swipeAmount)

        if (nextLoader.status === Loader.Loading) {
            // Next layout is not loaded yet.
            // We need to ensure that after it has been loaded the transition is correctly ended.
            nextLoader.loaded.connect(function endManualTransitionAfterLoaded() {
                // Disconnect; we don't wanna affect the next transition
                nextLoader.loaded.disconnect(endManualTransitionAfterLoaded)

                // Catch up on the current transition
                updateManualTransition(swipeAmount)
                endManualTransition()
            })
            return
        }

        if (swipeAmountAbs >= swipeSwitchGestureThreshold) {
            layoutTransition = layoutTransitionComponent.createObject(layoutRow)
        } else {
            layoutTransition = cancelLayoutTransitionComponent.createObject(layoutRow)

            // Unload layout that is not needed after all
            updateLoadersToLayoutAndNeighbours(canvas.activeIndex)
        }

        _manualTransition = false
        layoutTransition.start()
    }

    function finalizeTransition() {
        if (!nextLoader || !nextLoader.item) {
            // Don't do anything if the transition has been already cancelled
            return
        }

        nextLoader.item.y = 0
        layoutRow.layout = layoutRow.nextLoader.item

        if (keyboard.inputHandler) {
            keyboard.inputHandler.active = false // this input handler might not handle new layout
        }

        canvas.activeIndex = layoutRow.nextActiveIndex
        keyboard.updateInputHandler()
        keyboard.resetKeyboard()
        keyboard.applyAutocaps()

        // Connect the keyboard state with the new layout's state
        layoutRow.layout.attributes = keyboard

        var oldLoader = layoutRow.loader
        oldLoader.visible = false
        layoutRow.loader = layoutRow.nextLoader
        layoutRow.nextLoader = null
        previousLayout = canvas.layoutModel.get(oldLoader.index).layout

        layout.flashLanguageIndicator()

        // Unload layout that is not needed after all
        updateLoadersToLayoutAndNeighbours(canvas.activeIndex)
    }

    ConfigurationValue {
        id: previousLayoutConfig

        key: "/sailfish/text_input/previous_layout"
        defaultValue: ""
    }
}
