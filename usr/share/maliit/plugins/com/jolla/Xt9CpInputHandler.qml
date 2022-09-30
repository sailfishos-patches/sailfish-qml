import QtQuick 2.0
import com.meego.maliitquick 1.0
import com.jolla.keyboard 1.0
import com.jolla.xt9cp 1.0
import Sailfish.Silica 1.0
import org.nemomobile.configuration 1.0

InputHandler {
    id: handler

    Xt9CpModel {
        id: xt9CpModel

        property bool fetchMany
        property bool strokeInput: inputMethod === "china_stroke"

        fetchCount: fetchMany ? 120 : 20
        mohuEnabled: mohuConfig.value
        inputMode: keyboard.layout ? keyboard.layout.inputMode : ""
        inputMethod: keyboard.layout ? keyboard.layout.type : ""


        onInputMethodChanged: handler.clearPreedit()
        onInputModeChanged: handler.clearPreedit()
    }

    ConfigurationValue {
        id: mohuConfig

        key: "/sailfish/text_input/mohu_enabled"
        defaultValue: false
    }

    //  TODO:
    // optimize candidate phrase updating: input + setContext() to only do once, avoid on backspace autorepeat

    property bool composingEnabled: !keyboard.inSymView
    property bool hasMore: composingEnabled && xt9CpModel.maxCount > xt9CpModel.count

    onActiveChanged: {
        if (active) {
            xt9CpModel.setContext(MInputMethodQuick.surroundingText.substring(0, MInputMethodQuick.cursorPosition))
        } else {
            handler.clearPreedit()
        }
    }

    topItem: Component {
        Column {
            id: topItem
            width: parent  ? parent.width : 0

            TopItem {
                visible: (keyboardLayout.type === "china_stroke") && !keyboardLayout.attributes.inSymView
                width: parent.width

                Rectangle {
                    id: background
                    anchors.fill: parent
                    color: handler.palette.highlightBackgroundColor
                    opacity: .05
                }

                Label {
                    anchors.centerIn: parent
                    horizontalAlignment: Text.AlignHCenter
                    text: xt9CpModel.inputString
                }

                MouseArea {
                    // this produces child mouse events for TopItem close gesture
                    anchors.fill: parent
                }
            }

            TopItem {
                id: listTopItem
                width: parent.width

                SilicaListView {
                    id: listView

                    model: composingEnabled ? xt9CpModel : 0
                    orientation: ListView.Horizontal
                    width: parent.width
                    height: parent.height
                    boundsBehavior: ((!keyboard.expandedPaste && Clipboard.hasText) || handler.hasMore)
                                    ? Flickable.DragOverBounds : Flickable.StopAtBounds
                    header: pasteComponent

                    footer: Item {
                        width: handler.hasMore ? 30 : 0
                        height: listView.height
                        visible: handler.hasMore

                        Image {
                            source: "image://theme/icon-lock-more"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Icon {
                            source: "image://theme/icon-lock-more"
                            color: palette.highlightColor
                            anchors.verticalCenter: parent.verticalCenter
                            opacity: listView.dragging && listView.atXEnd ? 1.0 : 0.0
                            Behavior on opacity { FadeAnimation {} }
                        }
                    }

                    delegate: BackgroundItem {
                        id: backGround
                        onClicked: selectPhrase(model.text, model.index)
                        width: candidateText.width + Theme.paddingLarge * 2
                        height: listTopItem.height

                        Label {
                            id: candidateText
                            anchors.centerIn: parent
                            highlighted: backGround.down || (index === 0 && xt9CpModel.inputString.length > 0)
                            font { pixelSize: Theme.fontSizeSmall; family: Theme.fontFamily }
                            text: model.text
                        }
                    }
                    onDraggingChanged: {
                        if (!dragging) {
                            if (!keyboard.expandedPaste && contentX < -(headerItem.width + Theme.paddingLarge)) {
                                keyboard.expandedPaste = true
                                positionViewAtBeginning()
                            } else if (atXEnd && handler.hasMore) {
                                xt9CpModel.fetchMany = true
                            }
                        }
                    }

                    Binding on flickDeceleration {
                        when: phraseDialog.visible
                        value: 1000000
                    }

                    Connections {
                        target: xt9CpModel
                        onDataChanged: listView.positionViewAtBeginning()
                    }

                    Connections {
                        target: Clipboard
                        onTextChanged: {
                            if (Clipboard.hasText) {
                                // need to have updated width before repositioning view
                                positionerTimer.restart()
                            }
                        }
                    }

                    Timer {
                        id: positionerTimer
                        interval: 10
                        onTriggered: listView.positionViewAtBeginning()
                    }
                }
            }
        }
    }

    verticalItem: Component {
        Item {
            id: verticalContainer

            property int inactivePadding: Theme.paddingMedium

            SilicaListView {
                id: verticalList

                model: composingEnabled ? xt9CpModel : 0
                anchors.fill: parent
                clip: true
                boundsBehavior: handler.hasMore ? Flickable.DragOverBounds : Flickable.StopAtBounds

                header: Component {
                    PasteButtonVertical {
                        visible: Clipboard.hasText
                        width: verticalList.width
                        height: visible ? geometry.keyHeightLandscape : 0
                        popupParent: verticalContainer
                        popupAnchor: 2 // center

                        onClicked: {
                            if (xt9CpModel.inputString.length > 0) {
                                MInputMethodQuick.sendCommit(xt9CpModel.inputString)
                                xt9CpModel.resetState()
                            }
                            MInputMethodQuick.sendCommit(Clipboard.text)
                        }
                    }
                }

                footer: Item {
                    width:  verticalList.width
                    height: geometry.keyHeightLandscape / 2
                    visible: handler.hasMore

                    Image {
                        id: moreIcon
                        source: "image://theme/icon-lock-more"
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.bottom
                        anchors.verticalCenterOffset: -Theme.paddingSmall
                    }
                    Icon {
                        source: "image://theme/icon-lock-more"
                        anchors.centerIn: moreIcon
                        color: palette.highlightColor
                        opacity: verticalList.dragging && verticalList.atYEnd ? 1.0 : 0.0
                        Behavior on opacity { FadeAnimation {} }
                    }
                }

                delegate: BackgroundItem {
                    id: background
                    onClicked: selectPhrase(model.text, model.index)
                    width: parent.width
                    height: geometry.keyHeightLandscape * candidateText.lineCount

                    Label {
                        id: candidateText

                        width: background.width
                        horizontalAlignment: Text.AlignHCenter
                        anchors.verticalCenter: parent.verticalCenter
                        highlighted: background.down || (index === 0 && xt9CpModel.inputString.length > 0)
                        font { pixelSize: Theme.fontSizeSmall; family: Theme.fontFamily }
                        text: model.text
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                    }
                }

                onDraggingChanged: {
                    if (!dragging && atYEnd && handler.hasMore) {
                        xt9CpModel.fetchMany = true
                    }
                }

                Binding on flickDeceleration {
                    when: phraseDialog.visible
                    value: 1000000
                }

                Connections {
                    target: xt9CpModel
                    onDataChanged: {
                        if (!clipboardChange.running) {
                            verticalList.positionViewAtIndex(0, ListView.Beginning)
                        }
                    }
                }

                Connections {
                    target: Clipboard
                    onTextChanged: {
                        verticalList.positionViewAtBeginning()
                        clipboardChange.restart()
                    }
                }
                Timer {
                    id: clipboardChange
                    interval: 1000
                }
                MouseArea {
                    height: parent.height
                    width: verticalContainer.inactivePadding
                }

                MouseArea {
                    height: parent.height
                    width: verticalContainer.inactivePadding
                    anchors.right: parent.right
                }
            }
        }
    }

    onComposingEnabledChanged: {
        if (xt9CpModel.inputString.length > 0) {
            MInputMethodQuick.sendCommit(xt9CpModel.inputString)
            xt9CpModel.resetState()
        }
    }

    Rectangle {
        id: phraseDialog

        parent: keyboard
        z: 1
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: keyboard.currentLayoutHeight

        visible: xt9CpModel.fetchMany
        color: handler.palette.highlightDimmerColor
        opacity: 0.9
        clip: true

        MultiPointTouchArea {
            // prevent events leaking below
            anchors.fill: parent
            z: -1
        }

        SilicaFlickable {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: closeButton.left

            contentHeight: gridView.height

            Flow {
                id: gridView

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.paddingMedium

                property real cellWidth: width / (keyboard.portraitMode ? 5 : 8)

                Repeater {
                    model: phraseDialog.visible ? xt9CpModel : 0
                    delegate: BackgroundItem {
                        id: gridItemBackground

                        height: Theme.itemSizeSmall
                        width: Math.ceil((gridText.contentWidth + 2*Theme.paddingMedium) / gridView.cellWidth)
                               * gridView.cellWidth

                        onClicked: selectPhraseAndShrink(model.text, model.index)

                        Label {
                            id: gridText
                            anchors.verticalCenter: parent.verticalCenter
                            x: Theme.paddingMedium
                            font { pixelSize: Theme.fontSizeSmall; family: Theme.fontFamily }
                            text: model.text
                        }
                    }
                }
            }
        }

        IconButton {
            id: closeButton

            anchors {
                right: parent.right
                top: parent.top
                topMargin: Theme.paddingSmall
            }
            opacity: 0.6
            icon.source: "image://theme/icon-close-vkb"
            onClicked: xt9CpModel.fetchMany = false
        }
    }

    Component {
        id: pasteComponent
        PasteButton {
            visible: Clipboard.hasText
            onClicked: {
                if (xt9CpModel.inputString.length > 0) {
                    MInputMethodQuick.sendCommit(xt9CpModel.inputString)
                    xt9CpModel.resetState()
                }
                MInputMethodQuick.sendCommit(Clipboard.text)
                keyboard.expandedPaste = false
            }
        }
    }

    Connections {
        target: MInputMethodQuick
        onEditorStateUpdate: {
            if (active) {
                xt9CpModel.setContext(MInputMethodQuick.surroundingText.substring(0, MInputMethodQuick.cursorPosition))
            }
        }
        onCursorPositionChanged: {
            if (active) {
                xt9CpModel.fetchMany = false
            }
        }
    }

    Binding {
        target: keyboard
        property: "chineseOverrideForEnter"
        value: xt9CpModel.inputString.length > 0
    }

    function selectPhrase(phrase, index) {
        console.log("phrase clicked: " + phrase)
        MInputMethodQuick.sendCommit(phrase)
        xt9CpModel.acceptPhrase(index)
        if (xt9CpModel.inputString.length > 0 && !xt9CpModel.strokeInput) {
            MInputMethodQuick.sendPreedit(xt9CpModel.inputString)
        }
    }

    function selectPhraseAndShrink(phrase, index) {
        selectPhrase(phrase, index)
        xt9CpModel.fetchMany = false
    }

    function handleKeyClick() {
        keyboard.expandedPaste = false
        if (pressedKey.text === " ") {
            if (!composingEnabled) {
                return false
            }

            if (xt9CpModel.inputString.length > 0) {
                var candidate = xt9CpModel.firstCandidate()
                if (candidate.length > 0) {
                    MInputMethodQuick.sendCommit(candidate)
                    xt9CpModel.acceptPhrase(0)
                    if (!xt9CpModel.strokeInput && xt9CpModel.inputString.length > 0) {
                        // send remaining input string
                        MInputMethodQuick.sendPreedit(xt9CpModel.inputString)
                    }

                    return true
                }

                if (!xt9CpModel.strokeInput) {
                    MInputMethodQuick.sendCommit(xt9CpModel.inputString)
                }
                xt9CpModel.resetState()
                return true
            }

        } else if (pressedKey.key === Qt.Key_Return) {
            if (xt9CpModel.inputString.length > 0) {
                if (!xt9CpModel.strokeInput) {
                    MInputMethodQuick.sendCommit(xt9CpModel.inputString)
                }
                xt9CpModel.resetState()
                return true
            }

        } else if (pressedKey.key === Qt.Key_Backspace) {
            if (xt9CpModel.inputString.length > 0) {
                xt9CpModel.processBackspace()
                if (!xt9CpModel.strokeInput) {
                    MInputMethodQuick.sendPreedit(xt9CpModel.inputString)
                }

                if (keyboard.shiftState !== ShiftState.LockedShift) {
                    keyboard.shiftState = ShiftState.NoShift
                }

                return true
            }

        } else if (pressedKey.text.length !== 0 && composingEnabled) {
            var processSymbol = xt9CpModel.strokeInput ? xt9CpModel.isStrokeSymbol(pressedKey.text)
                                                       : xt9CpModel.isLetter(pressedKey.text)
            if (xt9CpModel.strokeInput
                  && xt9CpModel.inputString.length > 0
                  && xt9CpModel.count === 0) {
                // previous stroke didn't produce candidates, start over
                xt9CpModel.resetState()
            }

            if (processSymbol) {
                if (xt9CpModel.processSymbol(pressedKey.text)) {
                    if (!xt9CpModel.strokeInput) {
                        MInputMethodQuick.sendPreedit(xt9CpModel.inputString)
                    }
                } else {
                    // something went wrong
                    MInputMethodQuick.sendCommit(xt9CpModel.inputString + pressedKey.text)
                    xt9CpModel.resetState()
                }
            } else {
                if (xt9CpModel.strokeInput) {
                    MInputMethodQuick.sendCommit(pressedKey.text)
                } else {
                    MInputMethodQuick.sendCommit(xt9CpModel.inputString + pressedKey.text)
                }

                xt9CpModel.resetState()
            }

            if (keyboard.shiftState !== ShiftState.LockedShift) {
                keyboard.shiftState = ShiftState.NoShift
            }

            return true
        }

        return false
    }

    function reset() {
        xt9CpModel.resetState()
        xt9CpModel.fetchMany = false
    }

    function phraseCandidates(inputText) {
        return xt9CpModel.phraseCandidates(inputText)
    }

    function clearPreedit() {
        if (xt9CpModel.inputString.length > 0) {
            if (!xt9CpModel.strokeInput) {
                MInputMethodQuick.sendCommit(xt9CpModel.inputString)
            }
            xt9CpModel.resetState()
        }
    }
}
