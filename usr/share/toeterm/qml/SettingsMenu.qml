/*
    ThumbTerm Copyright Olli Vanhoja
    FingerTerm Copyright 2011-2012 Heikki Holstila <heikki.holstila@gmail.com>
    ToeTerm Copyright 2018 ROZZ, 2019-2020 Matti Viljanen <matti.viljanen@kapsi.fi>

    This file is part of ToeTerm.

    ToeTerm is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 2 of the License, or
    (at your option) any later version.

    ToeTerm is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with ToeTerm.  If not, see <http://www.gnu.org/licenses/>.
*/

import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.XmlListModel 2.0

Page {
    id: settingsPage
    property string currentSwipeLocking: util.settingsValue("ui/allowSwipe")
    property string currentShowMethod: util.settingsValue("ui/vkbShowMethod")
    property string currentDragMode: util.settingsValue("ui/dragMode")
    property int keyboardFadeOutDelay: util.settingsValue("ui/keyboardFadeOutDelay")
    property int showExtraLinesFromCursor: util.settingsValue("ui/showExtraLinesFromCursor")

    allowedOrientations: Orientation.All
    onVisibleChanged: {
        if(!visible && pageStack.currentPage === !settingsPage) {
            section1.expanded = false
            section2.expanded = false
            section3.expanded = false
            section4.expanded = false
            section5.expanded = false
        }
    }
    Item {
        id: layoutWindow
        property variant layouts: keyLoader.allAvailableLayouts()
        property string currentLayout: util.settingsValue("ui/keyboardLayout");
    }
    Item {
        id: urlWindow
        property variant urls: term.grabURLsFromBuffer()
    }
    Item {
        id: colorsWindow
        property variant schemes: keyLoader.availableColorSchemes()
        property string currentScheme: util.settingsValue("ui/colorScheme");
    }
    function applyCharset(charsetName) {
        util.setSettingsValue("terminal/charset", charsetName);
        ptyiface.changeCharset(charsetName);
    }
    SilicaFlickable {
        id: mainSettingsFlickable
        anchors.fill: parent
        contentHeight: settingsColumn.height + Theme.paddingLarge
        PullDownMenu {
            MenuItem {
                text: qsTr("About")
                onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
            }
            MenuItem {
                text: qsTr("New window")
                onClicked: util.openNewWindow();
            }
        }
        Column {
            id: settingsColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            PageHeader {
                title: appWindow.windowTitle
            }
            Row {
                id: cpMenu
                x: Theme.paddingLarge
                width: parent.width - Theme.paddingLarge * 2
                height: copyButton.height + Theme.paddingLarge * 2
                property bool enableCopy: util.terminalHasSelection()
                property bool enablePaste: util.canPaste()
                spacing: Theme.paddingLarge
                Button {
                    id: copyButton
                    text: qsTr("Copy")
                    width: parent.width / 2 - Theme.paddingLarge / 2
                    onClicked: {
                        term.copySelectionToClipboard();
                        cpMenu.enablePaste = util.canPaste()
                    }
                    enabled: cpMenu.enableCopy
                    anchors.verticalCenter: parent.verticalCenter
                }
                Button {
                    text: qsTr("Paste")
                    width: parent.width / 2 - Theme.paddingLarge / 2
                    onClicked: {
                        term.pasteFromClipboard();
                        pageStack.pop();
                    }
                    enabled: cpMenu.enablePaste
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            ExpandingSection {
                id: section1
                buttonHeight: Theme.iconSizeLarge
                title: qsTr("Actions")
                Component {
                    id: xmlDelegate
                    ListItem {
                        Label {
                            text: title
                            color: parent.highlighted ? Theme.highlightColor : Theme.primaryColor
                            x: Theme.paddingLarge
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        width: parent.width
                        enabled: (disableOn.length === 0 || windowTitle.search(disableOn) === -1) && section1.expanded
                        onClicked: {
                            term.putString(command, true);
                            pageStack.pop();
                        }
                    }
                }
                XmlListModel {
                    id: xmlModel
                    xml: term.getUserMenuXml()
                    query: "/userMenu/item"
                    XmlRole { name: "title"; query: "title/string()" }
                    XmlRole { name: "command"; query: "command/string()" }
                    XmlRole { name: "disableOn"; query: "disableOn/string()" }
                }
                content.sourceComponent: Column {
                    Repeater {
                        model: xmlModel
                        delegate: xmlDelegate
                    }
                }
            }
            ExpandingSection {
                id: section2
                buttonHeight: Theme.iconSizeLarge
                title: qsTr("URL grabber")
                Component {
                    id: listDelegate
                    ListItem {
                        enabled: section2.expanded
                        Label {
                            text: modelData
                            color: parent.highlighted ? Theme.highlightColor : Theme.primaryColor
                            x: Theme.paddingLarge
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        menu: ContextMenu {
                            MenuItem {
                                text: qsTr("Open")
                                onClicked: Qt.openUrlExternally(modelData);
                            }
                            MenuItem {
                                text: qsTr("Copy")
                                onClicked: {
                                    util.copyTextToClipboard(modelData);
                                    cpMenu.enablePaste = util.canPaste()
                                }
                            }
                        }
                    }
                }
                content.sourceComponent: ListView {
                    height: contentHeight
                    anchors.left: parent.left
                    anchors.right: parent.right
                    delegate: listDelegate
                    model: urlWindow.urls
                }
            }
            ExpandingSection {
                id: section3
                buttonHeight: Theme.iconSizeLarge
                title: qsTr("Keyboard layout")
                Component {
                    id: listDelegate2
                    TextSwitch {
                        enabled: section3.expanded
                        checked: keyLoader.layoutEnabled(modelData);
                        text: (modelData.charAt(0).toUpperCase() + modelData.slice(1)).split("_").join(" ");
                        onCheckedChanged: {
                            var wasone = keyLoader.availableLayouts().length === 1;
                            keyLoader.toggleLayout(modelData, checked);
                            checked = keyLoader.layoutEnabled(modelData);
                            if (keyLoader.availableLayouts().length === 1) {
                                var layout = keyLoader.availableLayouts()[0];
                                layoutWindow.currentLayout = layout;
                                util.setSettingsValue("ui/keyboardLayout", layout);
                                pageStack.previousPage().keyboardItem.reloadLayout();
                            } else if (wasone && keyLoader.availableLayouts().length === 2) {
                                pageStack.previousPage().keyboardItem.reloadLayout();
                            }
                        }
                    }
                }
                content.sourceComponent: ListView {
                    height: contentHeight
                    anchors.left: parent.left
                    anchors.right: parent.right
                    delegate: listDelegate2
                    model: layoutWindow.layouts
                }
            }
            ExpandingSection {
                id: section4
                buttonHeight: Theme.iconSizeLarge
                title: qsTr("Settings")
                content.sourceComponent: Column {
                    ComboBox {
                        id: orientationCombo
                        width: parent.width
                        label: qsTr("Allowed orientations")
                        property string sAll: qsTr("All")
                        property string sPort: qsTr("Portrait")
                        property string sLand: qsTr("Landscape")
                        property string sPortInv: qsTr("Portrait inverted")
                        property string sLandInv: qsTr("Landscape inverted")
                        menu: ContextMenu {
                            id: orientationMenu
                            MenuItem {
                                text: orientationCombo.sAll
                                onClicked: orientationCombo.orientationSave(15)
                                highlighted: orientationCombo.value === text
                            }
                            MenuItem {
                                text: orientationCombo.sPort
                                onClicked: orientationCombo.orientationSave(1)
                                highlighted: orientationCombo.value === text
                            }
                            MenuItem {
                                text: orientationCombo.sLand
                                onClicked: orientationCombo.orientationSave(2)
                                highlighted: orientationCombo.value === text
                            }
                            MenuItem {
                                text: orientationCombo.sPortInv
                                onClicked: orientationCombo.orientationSave(4)
                                highlighted: orientationCombo.value === text
                            }
                            MenuItem {
                                text: orientationCombo.sLandInv
                                onClicked: orientationCombo.orientationSave(8)
                                highlighted: orientationCombo.value === text
                            }
                        }
                        function orientationSave(newSetting) {
                            newSetting = parseInt(newSetting)
                            util.setSettingsValue("ui/allowedOrientations", newSetting)
                            switch(newSetting){
                            case 1: value  = sPort;    currentIndex = 1; break
                            case 2: value  = sLand;    currentIndex = 2; break
                            case 4: value  = sPortInv; currentIndex = 3; break
                            case 8: value  = sLandInv; currentIndex = 4; break
                            default: value = sAll;     currentIndex = 0;
                            }
                        }
                        Component.onCompleted: {
                            var newSetting = parseInt(util.settingsValue("ui/allowedOrientations"))
                            switch(newSetting) {
                            case 1: value = sPort;    currentIndex = 1; break;
                            case 2: value = sLand;    currentIndex = 2; break;
                            case 4: value = sPortInv; currentIndex = 3; break;
                            case 8: value = sLandInv; currentIndex = 4; break;
                            default: value = sAll;    currentIndex = 0;
                            }
                        }
                        enabled: section4.expanded
                    }
                    Slider {
                        enabled: section4.expanded
                        id: sizeSlider
                        label: qsTr("Font size")
                        width: parent.width
                        value: pageStack.previousPage() ? pageStack.previousPage().textRenderItem.fontPointSize : 11
                        minimumValue: 11
                        valueText: value
                        stepSize: 1
                        maximumValue: util.settingsValue("ui/maxFontSize")
                        onReleased: {
                            pageStack.previousPage().textRenderItem.fontPointSize = sliderValue;
                            pageStack.previousPage().lineViewItem.fontPointSize = sliderValue;
                        }
                    }
                    Row {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: dragSlider.height
                        Slider {
                            enabled: section4.expanded
                            id: dragSlider
                            label: qsTr("Drag mode")
                            width: parent.width/2
                            value: currentDragMode=="gestures" ? 0 : currentDragMode=="scroll" ? 1 : 2
                            minimumValue: 0
                            maximumValue: 2
                            stepSize: 1
                            valueText: value == 0 ? qsTr("Gestures") : value == 1 ? qsTr("Scroll") : qsTr("Select")
                            onReleased: {
                                currentDragMode = value == 0 ? "gestures" : value == 1 ? "scroll" : "select";
                                util.setSettingsValue("ui/dragMode", currentDragMode);
                                term.clearSelection();
                                cpMenu.enableCopy = util.terminalHasSelection()
                            }
                        }
                        Slider {
                            enabled: section4.expanded
                            label: qsTr("Keyboard behavior")
                            width: parent.width/2
                            value: currentShowMethod=="off" ? 0 : currentShowMethod=="fade" ? 1 : 2
                            minimumValue: 0
                            maximumValue: 2
                            stepSize: 1
                            valueText: value == 0 ? qsTr("Off") : value == 1 ? qsTr("Fade") : qsTr("Move")
                            onReleased: {
                                currentShowMethod = value == 0 ? "off" : value == 1 ? "fade" : "move";
                                util.setSettingsValue("ui/vkbShowMethod", currentShowMethod);
                                pageStack.previousPage().windowItem.setTextRenderAttributes();
                            }
                        }
                    }
                    Slider {
                        enabled: section4.expanded
                        label: qsTr("Keyboard delay")
                        width: parent.width
                        value: keyboardFadeOutDelay == 0 ? 10000 : keyboardFadeOutDelay
                        minimumValue: 1000
                        valueText: value < 10000 ? value + " " + qsTr("ms") : qsTr("No delay")
                        stepSize: 250
                        maximumValue: 10000
                        onReleased: {
                            if (sliderValue < 10000) {
                                keyboardFadeOutDelay = sliderValue
                                util.setSettingsValue("ui/keyboardFadeOutDelay", keyboardFadeOutDelay);
                            } else {
                                util.setSettingsValue("ui/keyboardFadeOutDelay", 0);
                            }
                        }
                    }
                    Slider {
                        enabled: section4.expanded
                        label: qsTr("Highlight box extra lines")
                        width: parent.width
                        value: showExtraLinesFromCursor
                        minimumValue: 0
                        maximumValue: 10
                        valueText: value
                        stepSize: 1
                        onReleased: {
                            util.setSettingsValue("ui/showExtraLinesFromCursor", value)
                            pageStack.previousPage().windowItem.displayBufferChanged()
                        }
                    }

                    ComboBox {
                        id: boxPosCombo
                        width: parent.width
                        label: qsTr("Highlight box position")
                        property string sTop: qsTr("top")
                        property string sBottom: qsTr("bottom")
                        menu: ContextMenu {
                            id: boxPosMenu
                            MenuItem {
                                text: boxPosCombo.sTop
                                onClicked: boxPosCombo.boxPosSave(true)
                                highlighted: boxPosCombo.value === boxPosCombo.sTop
                            }
                            MenuItem {
                                text: boxPosCombo.sBottom
                                onClicked: boxPosCombo.boxPosSave(false)
                                highlighted: boxPosCombo.value === boxPosCombo.sBottom
                            }
                        }
                        function boxPosSave(value) {
                            util.setSettingsValue("ui/dockLineviewToTop", value)
                            pageStack.previousPage().lineViewItem.anchorToTop = value
                            boxPosCombo.value = value ? sTop : sBottom
                        }
                        Component.onCompleted: {
                            currentIndex = util.settingsValueBool("ui/dockLineviewToTop") ? 0 : 1
                            value = currentIndex === 0 ? sTop : sBottom
                        }
                        enabled: section4.expanded
                    }

                    TextSwitch {
                        enabled: section4.expanded
                        checked: util.settingsValueBool("ui/keyPressFeedback")
                        width: parent.width
                        text: qsTr("Keyboard feedback")
                        onCheckedChanged: util.setSettingsValue("ui/keyPressFeedback", checked)
                    }
                    ComboBox {
                        id: charsetFieldCombo
                        width: parent.width
                        label: qsTr("Charset")
                        menu: ContextMenu {
                            id: charsetContextMenu
                            MenuItem { text: "UTF-8"; onClicked: charsetContextMenu.menuItemPress(text); highlighted: text == charsetFieldCombo.value }
                            MenuItem { text: "ISO 8859-1"; onClicked: charsetContextMenu.menuItemPress(text); highlighted: text == charsetFieldCombo.value }
                            MenuItem { text: "Windows-1252"; onClicked: charsetContextMenu.menuItemPress(text); highlighted: text == charsetFieldCombo.value }
                            MenuItem { text: "Macintosh"; onClicked: charsetContextMenu.menuItemPress(text); highlighted: text == charsetFieldCombo.value }
                            MenuItem { text: "KOI8-R"; onClicked: charsetContextMenu.menuItemPress(text); highlighted: text == charsetFieldCombo.value }
                            MenuItem { text: "KOI8-U"; onClicked: charsetContextMenu.menuItemPress(text); highlighted: text == charsetFieldCombo.value }
                            MenuItem { text: qsTr("Custom"); onClicked: {
                                    charsetField.visible = true;
                                    charsetField.text = "";
                                    charsetFieldCombo.visible = false;
                                    charsetField.focus = true;
                                    scrollDownTimer.restart();
                                }
                            }
                            function menuItemPress(text) {
                                applyCharset(text);
                                charsetFieldCombo.value = text;
                            }
                        }
                        value: util.settingsValue("terminal/charset")
                        enabled: section4.expanded
                    }
                    TextField {
                        id: charsetField
                        visible: false
                        width: parent.width
                        label: qsTr("Apply with Enter key")
                        placeholderText: qsTr("Custom charset")
                        EnterKey.onClicked: {
                            if (!text)
                                  text = "UTF-8"
                            applyCharset(text);
                            charsetFieldCombo.value = text;
                            visible = false;
                            charsetFieldCombo.visible = true;
                        }
                        enabled: section4.expanded
                    }
                    TextSwitch {
                        id: transSwitch
                        enabled: section4.expanded
                        checked: !util.settingsValueBool("ui/showBackground")
                        width: parent.width
                        text: qsTr("Transparent background")
                        onCheckedChanged: {
                            util.setSettingsValue("ui/showBackground", !checked);
                            pageStack.previousPage().bgDrawItem.visible = util.settingsValueBool("ui/showBackground");
                            pageStack.previousPage().bgTimerItem.restart();
                        }
                    }
                }
            }
            ExpandingSection {
                id: section5
                buttonHeight: Theme.iconSizeLarge
                title: qsTr("Color scheme")
                Component {
                    id: listDelegate3
                    ListItem {
                        enabled: section5.expanded
                        highlighted: colorsWindow.currentScheme === modelData
                        Label {
                            text: modelData.split("_").join(" ")
                            color: parent.highlighted ? Theme.highlightColor : Theme.primaryColor
                            x: Theme.paddingLarge
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        onClicked: {
                            colorsWindow.currentScheme = modelData;
                            util.setSettingsValue("ui/colorScheme", modelData);
                            pageStack.previousPage().textRenderItem.loadColorScheme(modelData);
                            pageStack.previousPage().bgDrawItem.color = "#" + pageStack.previousPage().textRenderItem.getColor("colors/bgColor");
                            pageStack.previousPage().bgTimerItem.restart();
                        }
                    }
                }
                content.sourceComponent: ListView {
                    height: contentHeight
                    anchors.left: parent.left
                    anchors.right: parent.right
                    delegate: listDelegate3
                    model: colorsWindow.schemes
                }
            }
        }
        VerticalScrollDecorator { }
    }
}
