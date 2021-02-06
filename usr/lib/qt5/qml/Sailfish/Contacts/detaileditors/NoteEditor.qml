import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Contacts 1.0
import org.nemomobile.contacts 1.0

MultiTypeFieldEditor {
    id: root

    function populateFieldEditor() {
        detailModel.reload(contact[propertyAccessor])
        detailSubTypeModel.reload(allowedTypes, allowedSubTypes)

        // User can only add notes if there are zero notes for this contact. This follows the
        // style of typical contact services that only allow one note per contact. However, if
        // a contact has multiple notes (e.g. synced from some service that does allow multiple
        // notes to be created) then these will be shown.
        if (detailModel.count === 0) {
            addEmptyField()
        }
    }

    //: Add a note for this contact
    //% "Add note"
    fieldAdditionText: qsTrId("contacts-bt-contact_add_note")
    fieldAdditionIcon: "image://theme/icon-m-note"

    propertyAccessor: 'noteDetails'
    valueField: 'note'
    allowedTypes: [ Person.NoteType ]
    canChangeLabelType: false

    fieldDelegate: Item {
        id: noteDelegate

        width: parent.width
        height: inputField.height

        AddFieldButton {
            id: addFieldButton

            x: parent.width - width - Theme.paddingMedium
            text: root.fieldAdditionText
            icon.source: root.fieldAdditionIcon
            animate: root.ready
            opacity: enabled ? 1 : 0
            highlighted: down || inputField.activeFocus

            onClicked: {
                offscreen = true
                inputField.forceActiveFocus()
            }
        }

        TextArea {
            id: inputField

            height: implicitHeight  // explicit binding needed to trigger height Behavior
            textLeftMargin: addFieldButton.offscreenPeekWidth

            activeFocusOnTab: addFieldButton.offscreen
            highlighted: activeFocus || addFieldButton.highlighted
            opacity: addFieldButton.revealedContentOpacity
            enabled: addFieldButton.offscreen
            focus: root.initialFocusIndex === model.index

            text: model.value
            label: model.name
            placeholderText: model.name

            onTextChanged: {
                if (text.length > 0) {
                    addFieldButton.offscreen = true
                }
                if (activeFocus) {
                    root.detailModel.userModified = true
                    root.detailModel.setProperty(model.index, "value", text)
                }
            }

            // Don't autoscroll to beneath the DialogHeader
            VerticalAutoScroll.topMargin: Theme.itemSizeLarge

            Behavior on height {
                id: noteHeightAnimation

                enabled: false

                NumberAnimation {
                    duration: root.animationDuration
                    easing.type: Easing.InOutQuad
                    onRunningChanged: noteHeightAnimation.enabled = false
                }
            }

            rightItem: IconButton {
                onClicked: {
                    root.detailModel.userModified = true
                    if (inputField.text.length > 0) {
                        noteHeightAnimation.enabled = true
                        root.detailModel.setProperty(model.index, "value", "")
                        inputField.text = ""
                    } else {
                        root.detailModel.setProperty(model.index, "value", "")
                        if (!root.animateAndRemove(model.index, noteDelegate)) {
                            addFieldButton.offscreen = false
                        }
                    }
                }

                width: icon.width
                height: icon.height

                icon.source: inputField.text.length > 0
                             ? "image://theme/icon-splus-clear"
                             : "image://theme/icon-splus-remove"
                enabled: addFieldButton.offscreen
                opacity: enabled ? addFieldButton.revealedContentOpacity : 0
                Behavior on opacity { FadeAnimation {} }
            }
        }
    }
}

