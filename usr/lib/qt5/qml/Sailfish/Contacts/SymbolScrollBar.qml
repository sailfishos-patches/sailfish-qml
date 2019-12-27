import QtQuick 2.5
import Sailfish.Silica 1.0
import org.nemomobile.contacts 1.0

Item {
    id: root

    property alias model: symbolRepeater.model
    property alias favoriteIconEnabled: favoriteIcon.enabled
    property alias recentIconEnabled: recentIcon.enabled

    property real leftPadding: Theme.paddingMedium
    property real rightPadding: Theme.paddingMedium

    readonly property bool hasSymbols: symbolRepeater.count > 0
    readonly property int displayableSymbolCount: Math.floor(symbolColumn.height / _symbolBoxSize) - _additionalSymbolCount
    readonly property bool pressed: overlayMouseArea.pressed

    signal favoriteIconClicked()
    signal recentIconClicked()
    signal symbolClicked(int symbolIndex, string symbol)

    function highlightFavoriteIcon() {
        if (favoriteIcon.enabled) {
            _currentItem = favoriteIcon
            _currentSymbol = ""
            return true
        }
        return false
    }

    function highlightRecentIcon() {
        if (recentIcon.enabled) {
            _currentItem = recentIcon
            _currentSymbol = ""
            return true
        }
        return false
    }

    function highlightSymbolIndex(symbolIndex, symbol) {
        if (symbol == _currentSymbol) {
            return false
        }

        var item = symbolRepeater.itemAt(symbolIndex)
        if (item) {
            _currentItem = item
            _currentSymbol = symbol
            return true
        } else {
            console.log("Can't find symbol", symbol, "at index:", symbolIndex)
            return false
        }
    }

    function resetScrollPosition() {
        if (!highlightFavoriteIcon() && !highlightRecentIcon()) {
            highlightSymbolIndex(0, model.get(0, PeopleDisplayLabelGroupModel.NameRole))
        }
    }


    //--- Internal properties and functions: ---

    // Highlight first available item as the default.
    property Item _currentItem: {
        if (favoriteIconEnabled) {
            return favoriteIcon
        } else if (recentIconEnabled) {
            return recentIcon
        }
        return symbolRepeater.itemAt(0)
    }
    property string _currentSymbol
    property real _mouseX
    property real _mouseY

    readonly property int _symbolSize: Theme.iconSizeSmall
    readonly property int _symbolBoxSize: Theme.iconSizeSmall * 1.25
    readonly property int _additionalSymbolCount: 2   // favorite, recent
    readonly property int _totalSymbolCount: (symbolRepeater.count + _additionalSymbolCount)

    function _setCurrentItem(item, symbolIndex, symbol) {
        var changeItem = _currentItem !== item
        var changeSymbol = symbol !== _currentSymbol
        if (!changeItem && !changeSymbol) {
            return
        }

        _currentSymbol = symbol || ""
        _currentItem = item
        if (_currentItem == null) {
            return
        }

        if (item === favoriteIcon) {
            root.favoriteIconClicked()
        } else if (item === recentIcon) {
            root.recentIconClicked()
        } else if (symbolIndex !== undefined) {
            root.symbolClicked(symbolIndex, symbol)
        }
    }

    function _updateCurrentItem() {
        // Add column spacing above and below into calculations to avoid gaps in symbol hit test
        // when spacing is > 0
        var itemIndex = Math.floor((_mouseY + symbolColumn.spacing/2) / (root._symbolBoxSize + symbolColumn.spacing))

        // Set current item to favorite/recent if these sections are enabled.
        if (itemIndex <= 0 && favoriteIcon.enabled) {
            root._setCurrentItem(favoriteIcon)
            return
        } else if (itemIndex <= 1 && recentIcon.enabled) {
            root._setCurrentItem(recentIcon)
            return
        }

        // Set a symbol as the current item. Use the first/last symbol if scrolled beyond extents.
        itemIndex = Math.max(0, Math.min(itemIndex - _additionalSymbolCount, symbolRepeater.count-1))

        var item = symbolRepeater.itemAt(itemIndex)
        if (item) {
            var compressed = symbolRepeater.model.get(itemIndex, PeopleDisplayLabelGroupModel.CompressedRole)
            if (compressed) {
                // If this index refers to a compressed group, find the symbol within the
                // compressed group that is closest to the current mouse position.
                var localMouseY = item.mapFromItem(overlayMouseArea, 0, _mouseY).y
                var compressedSymbols = symbolRepeater.model.get(itemIndex, PeopleDisplayLabelGroupModel.CompressedContentRole)
                if (compressedSymbols.length > 0) {
                    var yPosRatio = localMouseY / root._symbolBoxSize
                    var subGroupIndex = Math.max(0, Math.min(compressedSymbols.length - 1, Math.floor(compressedSymbols.length * yPosRatio)))
                    root._setCurrentItem(item, itemIndex + subGroupIndex, compressedSymbols[subGroupIndex])
                    return
                }
            }
            root._setCurrentItem(item, itemIndex, symbolRepeater.model.get(itemIndex, PeopleDisplayLabelGroupModel.NameRole))
        }
    }

    implicitWidth: leftPadding + symbolColumn.width + rightPadding

    Rectangle {
        id: symbolMagnifier

        anchors {
            right: parent.right
            rightMargin: symbolColumn.width + root.rightPadding + Theme.paddingLarge*2
        }
        y: Math.max(0, Math.min(overlayMouseArea.mouseY - height/2, parent.height - height))
        width: symbolMagnifierImage.width + Theme.paddingLarge*2
        height: width

        opacity: 0
        radius: width
        color: Theme.rgba(Theme.secondaryHighlightColor, 0.7)

        Label {
            anchors {
                fill: parent
                margins: Theme.paddingMedium
            }
            text: root._currentItem && root._currentItem.text !== undefined ? root._currentSymbol : ""
            color: Theme.primaryColor
            font.pixelSize: Theme.fontSizeHuge
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            fontSizeMode: Text.Fit
        }

        Image {
            id: symbolMagnifierImage

            anchors.centerIn: parent
            source: root._currentItem === favoriteIcon
                    ? "image://theme/icon-m-favorite"
                    : (root._currentItem === recentIcon ? "image://theme/icon-m-time" : "")
            width: Theme.fontSizeHuge
            height: Theme.fontSizeHuge
        }
    }

    Column {
        id: symbolColumn

        x: root.width - width - root.rightPadding
        width: root._symbolBoxSize
        height: parent.height

        // Apply maximum spacing between items, given the available column height
        spacing: Math.max(0, Math.floor(height - (_totalSymbolCount * _symbolBoxSize)) / Math.max(1, root._totalSymbolCount - 1))

        Item {
            id: favoriteIconBox

            width: parent.width
            height: root._symbolBoxSize

            HighlightImage {
                id: favoriteIcon

                anchors.centerIn: parent
                source: "image://theme/icon-s-favorite"
                sourceSize.width: root._symbolSize
                sourceSize.height: root._symbolSize
                opacity: highlighted ? 1 : (enabled ? Theme.opacityHigh : Theme.opacityFaint)
                highlighted: root._currentItem === favoriteIcon
            }
        }

        Item {
            id: recentIconBox

            width: parent.width
            height: root._symbolBoxSize

            HighlightImage {
                id: recentIcon

                anchors.centerIn: parent
                source: "image://theme/icon-s-time"
                sourceSize.width: root._symbolSize
                sourceSize.height: root._symbolSize
                opacity: highlighted ? 1 : (enabled ? Theme.opacityHigh : Theme.opacityFaint)
                highlighted: root._currentItem === recentIcon
            }
        }

        Repeater {
            id: symbolRepeater

            delegate: Label {
                id: symbolDelegate

                width: parent.width
                height: root._symbolBoxSize
                text: model.compressed ? '\u2022' : model.name
                font.pixelSize: root._symbolSize
                color: symbolDelegate === root._currentItem
                       ? Theme.highlightColor
                       : Theme.secondaryColor
                font.bold: symbolDelegate === root._currentItem
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    MouseArea {
        id: overlayMouseArea

        width: root.width
        height: symbolColumn.height
        preventStealing: true

        onMouseYChanged: {
            _mouseX = mouseX
            _mouseY = mouseY
            _updateCurrentItem()
        }
    }

    states: State {
        name: "showMagnifier"
        when: overlayMouseArea.pressed && root._currentItem != null
        PropertyChanges { target: symbolMagnifier; opacity: 1 }
    }

    transitions: Transition {
        id: magnifierFadeTransition
        from: "showMagnifier"; to: "*"

        // Fade the magnifier slightly faster when moving over a dot than when moving off the
        // scrollbar altogether.
        FadeAnimation { target: symbolMagnifier; duration: root._currentItem != null ? 200 : 100 }
    }
}
