/*
 * Copyright (c) 2013 – 2020 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Contacts 1.0 as Contacts

Item {
    id: root
    property ListModel recipientsModel
    property bool addAction
    property bool inFocusedList
    property alias placeholderText: inputField.placeholderText
    property alias hasFocus: inputField.activeFocus
    property alias animating: autoCompleteAnim.running
    property bool empty: inputField.text == ""
    property bool editing
    property bool editable: !inputField.readOnly
    property alias inputMethodHints: inputField.inputMethodHints
    property alias labelVisible: inputField.labelVisible
    property bool expanded
    readonly property bool canExpand: model.formattedNameText.length > 0 && inputField.readOnly
    property QtObject onlineSearchModel
    property string onlineSearchDisplayName

    signal nextField()
    signal backspacePressed()

    function forceActiveFocus() {
        if (editable) {
            inputField.forceActiveFocus()
        }
    }

    function clearFocus() {
        inputField.focus = false
    }

    function clearText() {
        inputField.text = ""
    }

    function updateModelText() {
        inputField.updateModelText()
    }

    enabled: !deleteAnimation.running
    width: parent.width
    height: Math.max(inputField.height + (!animating ? autoComplete.height : 0),
                     (expanded ? (contactInfo.y + contactInfo.height + Theme.paddingSmall) : 0))
    Behavior on height {
        NumberAnimation {
            duration: 100
            easing.type: Easing.InOutQuad
        }
    }
    opacity: 0.0
    NumberAnimation on opacity { to: 1.0; running: true }

    MouseArea {
        id: expandMouseArea
        property bool down: pressed && containsMouse
        anchors {
            fill: parent
            bottomMargin: expanded ? 0 : Theme.paddingSmall * 2 // offset the margin included in the TextField's height
        }
        onClicked: expanded = !expanded
        enabled: !inputField.enabled
    }

    TextField {
        id: inputField

        property string trimmedText: text.trim()

        function updateModelText() {
            addressesModel.contact = null
            if (model.index != -1 && model.formattedNameText == "") {
                text = trimmedText
                recipientsModel.updateRecipientAddress(model.index, text)
            }
        }

        enabled: !readOnly && !deleteAnimation.running
        opacity: 1.0 // Don't set opacity to 0 when disabled
        width: parent.width - actionButton.width
        textRightMargin: Theme.horizontalPageMargin - Theme.paddingLarge + 2 * Theme.paddingSmall
        label: placeholderText
        onReadOnlyChanged: {
            if (readOnly) {
                focus = false
            }
        }
        color: (readOnly && canExpand && !expandMouseArea.down) ? Theme.primaryColor : Theme.highlightColor
        placeholderColor: Theme.secondaryHighlightColor
        focusOutBehavior: FocusBehavior.KeepFocus

        focusOnClick: !readOnly

        function updateFromContact(contact, index) {
            var address = _addressList(contact)[index]
            recipientsModel.updateRecipient(model.index,
                                            address.property, address.propertyType,
                                            contact ? contact.displayLabel : '', contact)
            text = model.formattedNameText
            recipientsModel.nextRecipient(model.index)
            readOnly = true
        }

        function updateFromKnownContact(item, name, email) {
            recipientsModel.updateRecipient(model.index,
                                            { "address": email }, "emailAddress",
                                            name, undefined, item)
            text = name
            recipientsModel.nextRecipient(model.index)
        }

        function textValue() {
            var val = model.formattedNameText !== "" ? model.formattedNameText
                                                     : ContactsUtil.propertyAddressValue(model.propertyType, model.property)
            return val === undefined ? "" : val
        }

        EnterKey.onClicked: {
            recipientsModel.updateRecipientAddress(model.index, text)
            nextField()
        }
        EnterKey.iconSource: "image://theme/icon-m-enter-next"

        onTextChanged: {
            if (!readOnly) {
                addressesModel.contact = null
                var origText = text
                text = text.replace(/[,;]/g, "")
                if (text != origText) {
                    // Separator character found, add new recipient.
                    text = text.trim() // cannot use trimmedText here because it's not evaluated yet
                    if (text != "") {
                        recipientsModel.updateRecipientAddress(model.index, text)
                        recipientsModel.nextRecipient(model.index)
                    }
                }
                autoComplete.searchText = text
            }
        }

        onActiveFocusChanged: {
            if (activeFocus) {
                text = textValue()
            } else {
                updateModelText()
            }
        }

        Component.onCompleted: {
            text = textValue()
            if (model.formattedNameText != "") {
                readOnly = true
            }
            // TODO: Replace with "Keys.onPressed" once JB#16601 is implemented.
            inputField._editor.Keys.pressed.connect(function(event) {
                if (event.key === Qt.Key_Backspace) {
                    root.backspacePressed()
                }
            })
        }
    }

    Label {
        id: contactInfo
        opacity: expanded ? 1.0 : 0.0
        Behavior on opacity { FadeAnimator { duration: 100 } }
        anchors {
            top: inputField.bottom
            topMargin: -Theme.paddingSmall * 3 // offset the margin included in the TextField's height
            left: parent.left
            leftMargin: Theme.horizontalPageMargin
            right: parent.right
            rightMargin: Theme.horizontalPageMargin
        }
        color: expandMouseArea.down ? Theme.secondaryHighlightColor : Theme.secondaryColor
        font.pixelSize: Theme.fontSizeSmall
        text: ContactsUtil.propertyAddressValue(model.propertyType, model.property)
    }

    Binding {
        when: autoCompleteList.model == contactSearchModel
        target: contactSearchModel
        property: "filterPattern"
        value: autoComplete.searchText
    }

    IconButton {
        id: actionButton
        enabled: root.inFocusedList && !deleteAnimation.running
        opacity: root.inFocusedList ? 1.0 : 0.0
        Behavior on opacity { FadeAnimator {} }
        anchors {
            right: parent.right
            rightMargin: Theme.horizontalPageMargin - Theme.paddingLarge + Theme.paddingSmall
            verticalCenter: inputField.top
            verticalCenterOffset: inputField.textVerticalCenterOffset
        }
        icon.source: addAction
                     ? "image://theme/icon-m-add"
                     : "image://theme/icon-m-remove"
        onClicked: {
            if (addAction) {
                // Add recipient
                addressesModel.contact = null
                recipientsModel.pickRecipients()
            } else {
                deleteAnimation.start()
            }
        }

        SequentialAnimation {
            id: deleteAnimation

            ParallelAnimation {
                FadeAnimator {
                    target: root
                    from: 1.0
                    to: 0.0
                }

                NumberAnimation {
                    target: root
                    duration: 200
                    property: "height"
                    to: 0
                }
            }

            ScriptAction {
                script: {
                    // Remove recipient
                    addressesModel.contact = null
                    recipientsModel.removeRecipient(model.index, inputField.activeFocus)
                }
            }
        }
    }

    Item {
        id: autoComplete
        property string searchText
        width: parent.width
        height: contactHeader.height + autoCompleteList.height + onlineSearchLoader.height
        anchors.top: inputField.bottom
        opacity: editing && !inputField.readOnly ? 1.0 : 0.0
        Behavior on opacity { FadeAnimation { id: autoCompleteAnim } }

        SectionHeader {
            id: contactHeader
            visible: onlineSearchLoader.active && autoCompleteList.model && autoCompleteList.model.count > 0
            height: visible ? implicitHeight : 0
            //: Shown as a section header for local contacts when there are multiple address books
            //% "Contacts"
            text: qsTrId("components_contacts-he-contacts")
        }

        ColumnView {
            id: autoCompleteList
            anchors.top: contactHeader.bottom
            width: parent.width
            itemHeight: Theme.itemSizeSmall
            model: ((editing || animating) && addressesModel.count)
                   ? addressesModel
                   : ((editing || animating) && inputField.trimmedText != "")
                     ? contactSearchModel
                     : null

            delegate: BackgroundItem {
                id: contactItem
                width: autoCompleteList.width
                height: isPortrait ? Theme.itemSizeSmall : Theme.itemSizeExtraSmall

                property var pendingContact: null

                Label {
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        leftMargin: Theme.horizontalPageMargin
                        rightMargin: Theme.horizontalPageMargin
                    }
                    truncationMode: TruncationMode.Fade
                    textFormat: Text.StyledText
                    text: Theme.highlightText(model.displayLabel, inputField.trimmedText, Theme.highlightColor)
                    color: contactItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                }
                Connections {
                    target: pendingContact
                    onCompleteChanged: {
                        if (pendingContact.complete) {
                            update()
                        }
                    }
                }

                onClicked: update()
                function update() {
                    pendingContact = null
                    var contact = null
                    var addressIndex = 0
                    if (autoCompleteList.model == contactSearchModel) {
                        contact = contactSearchModel.personByRow(model.index)
                        if (!contact.complete) {
                            pendingContact = contact
                            contact.ensureComplete()
                            return
                        }
                        var addresses = _addressList(contact)
                        if (contact && addresses.length != 1) {
                            if (addresses.length > 1) {
                                addressesModel.contact = contact
                            }
                            return
                        }
                    } else {
                        contact = addressesModel.contact
                        addressIndex = model.index
                    }
                    if (contact) {
                        inputField.updateFromContact(contact, addressIndex)
                    }
                }
            }

            Loader {
                id: onlineSearchLoader

                active: onlineSearchModel !== null && (autoCompleteList.model && autoCompleteList.model.count < 9)
                height: active ? implicitHeight : 0
                sourceComponent: Component {
                    OnlineSearchItem {
                        active: root.editing && autoComplete.searchText.length >= 1
                        onlineSearchModel: root.onlineSearchModel
                        onlineSearchDisplayName: root.onlineSearchDisplayName
                        searchText: autoComplete.searchText
                        width: parent ? parent.width : 0

                        function updateFromKnownContact(contact, name, email) {
                            inputField.updateFromKnownContact(contact, name, email)
                        }
                    }
                }
                anchors {
                    left: autoCompleteList.left
                    top: autoCompleteList.bottom
                    right: autoCompleteList.right
                }
            }
        }
    }
}
