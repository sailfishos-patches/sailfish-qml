/*
 * Copyright (c) 2012 - 2019 Jolla Ltd.
 * Copyright (c) 2019 Open Mobile Platform LLC.
 *
 * License: Proprietary
*/

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0 as Private
import Sailfish.Contacts 1.0
import org.nemomobile.contacts 1.0

FocusScope {
    id: root

    property alias icon: addFieldButton.icon
    property alias value: inputField.text
    property alias placeholderText: inputField.placeholderText
    property alias inputMethodHints: inputField.inputMethodHints
    property bool canRemove

    property alias buttonModeText: addFieldButton.text
    property bool buttonMode
    property alias showIconWhenEditing: addFieldButton.showIconWhenOffscreen

    property bool animate
    property alias animationDuration: addFieldButton.animationDuration
    property alias leftMargin: inputField.textLeftMargin
    property alias rightMargin: inputField.textRightMargin
    readonly property alias hasFocus: inputField.activeFocus
    property string keyboardEnterIcon: "image://theme/icon-m-enter-next"

    property int detailSubType
    property int detailLabel
    property var detailSubTypeModel
    property bool showDetailLabelCombo

    property bool _addButtonClicked
    property bool _textWasEntered

    property ContactDetailSuggestions suggestions
    property int suggestionField: ContactDetailSuggestions.None

    signal clickedInButtonMode()
    signal enteredButtonMode()
    signal modified()
    signal removeClicked()
    signal accepted()

    signal detailSubTypeModified(int type, int subType)
    signal detailLabelModified(int label)

    function forceActiveFocus() {
        inputField.forceActiveFocus()
    }

    function clearFocus() {
        inputField.focus = false
    }

    width: parent.width
    height: inputField.height

    TextField {
        id: inputField

        width: parent.width
        textLeftMargin: addFieldButton.offscreenPeekWidth

        readOnly: !root.enabled
        highlighted: activeFocus
        opacity: addFieldButton.text.length ? addFieldButton.revealedContentOpacity : 1
        enabled: addFieldButton.offscreen

        EnterKey.iconSource: root.keyboardEnterIcon
        EnterKey.onClicked: root.accepted()

        focus: true

        onTextChanged: {
            if (activeFocus) {
                // Once text changes, avoid returning to button mode.
                root._textWasEntered = true
                root.modified()
            }
        }

        onActiveFocusChanged: {
            if (activeFocus && root.suggestions) {
                root.suggestions.field = root.suggestionField
                if (root.suggestionField !== ContactDetailSuggestions.None) {
                    root.suggestions.partialText = Qt.binding(function() {
                        return inputField.text
                    })
                    root.suggestions.inputItem = inputField._editor
                }
            }
        }

        label: !!root.detailSubTypeModel ? "" : placeholderText
        labelComponent: (!!root.detailSubTypeModel || root.showDetailLabelCombo)
                        ? miniCombosComponent
                        : inputField.defaultLabelComponent

        Component {
            id: miniCombosComponent

            Row {
                id: miniCombos

                readonly property real initialHeight: detailSubTypeCombo.contentHeight

                width: parent.width
                spacing: Theme.paddingSmall

                MiniComboBox {
                    id: detailSubTypeCombo

                    label: root.placeholderText
                    visible: !!root.detailSubTypeModel
                    menu: DetailSubTypeMenu {
                        model: root.detailSubTypeModel
                        currentSubType: root.detailSubType

                        onCurrentIndexChanged: detailSubTypeCombo.currentIndex = currentIndex
                        onSubTypeClicked: root.detailSubTypeModified(type, subType)
                    }
                }

                MiniComboBox {
                    id: detailLabelCombo

                    // When 'None' is selected, show 'Select label' instead.
                    value: (!!currentItem && currentItem.text == ContactsUtil.getNoLabelText())
                           ? ContactsUtil.getSelectLabelText()
                           : currentItem.text

                    menu: DetailLabelMenu {
                        currentLabel: root.detailLabel

                        onCurrentIndexChanged: detailLabelCombo.currentIndex = currentIndex
                        onLabelClicked: root.detailLabelModified(label)
                    }
                }
            }
        }

        rightItem: IconButton {
            onClicked: {
                addFieldButton.animate = true
                if (inputField.text.length > 0) {
                    inputField.text = ""
                    root.modified()
                    inputField.forceActiveFocus()
                } else {
                    root.removeClicked()
                }
            }

            width: icon.width
            height: icon.height
            opacity: enabled ? addFieldButton.revealedContentOpacity : 0

            enabled: addFieldButton.offscreen
            icon.source: inputField.text.length > 0
                         ? "image://theme/icon-splus-clear"
                         : (canRemove ? "image://theme/icon-splus-remove" : "")
            Behavior on opacity { FadeAnimation {} }
        }
    }

    AddFieldButton {
        id: addFieldButton

        x: parent.width - width - Theme.paddingMedium

        offscreen: !root.buttonMode
        highlighted: inputField.activeFocus || down

        onClicked: {
            animate = true
            root._addButtonClicked = true
            if (root.buttonMode) {
                root.clickedInButtonMode()
            } else {
                inputField.forceActiveFocus()
            }
        }

        onEnteredButtonMode: {
            root.enteredButtonMode()
        }

        onExitedButtonMode: {
            inputField.forceActiveFocus()
        }
    }
}
