import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Contacts 1.0
import org.nemomobile.contacts 1.0

MultiTypeFieldEditor {
    id: root

    function aboutToSave() {
        if (detailModel.userModified) {
            // Copy modified values from detailEditors to detailModel before saving.
            for (var i = 0; i < detailModel.count; ++i) {
                detailModel.setProperty(i, "value", detailEditors.itemAt(i).addressFields.editedAddressAsString())
            }

            detailModel.copyMultiTypeDetailChanges(contact, propertyAccessor)
        }
    }

    function _testHasAddressContent() {
        for (var i = 0; i < detailEditors.count; ++i) {
            var delegate = detailEditors.itemAt(i)
            if (delegate && testHasContent(delegate.addressFields)) {
                return true
            }
        }
        return false
    }

    //: Add an address for this contact
    //% "Add address"
    fieldAdditionText: qsTrId("contacts-bt-contact_add_address")
    fieldAdditionIcon: "image://theme/icon-m-location"

    propertyAccessor: 'addressDetails'
    valueField: 'address'
    allowedTypes: [ Person.AddressType ]
    subTypesExclusive: false
    allowedSubTypes: {
        var subTypes = {}
        subTypes[Person.AddressType] = [
            Person.AddressSubTypeParcel,
            Person.AddressSubTypePostal,
            Person.AddressSubTypeDomestic,
            Person.AddressSubTypeInternational
        ]
        return subTypes
    }

    spacing: Theme.paddingMedium

    // Each address delegate contains a set of input fields to edit each part of the address
    // (street, city etc.) individually.
    fieldDelegate: Item {
        id: addressDelegate

        property var addressFields: AddressFieldModel {}
        property int addressIndex: model.index
        property int addressSubType: model.subType === undefined ? -1 : model.subType
        property int addressLabel: model.label
        property bool aboutToDelete

        function forceActiveFocus(delayInterval) {
            if (addressFieldsRepeater.count > 0) {
                return addressFieldsRepeater.itemAt(0).forceActiveFocus(delayInterval)
            }
            return false
        }

        width: parent.width
        height: addAddressButton.height + addressFieldsColumn.height

        Component.onCompleted: {
            addressFields.reload(model.value)

            // Now the address is loaded, break the button binding so that the button state doesn't
            // change whenever the model value changes.
            addAddressButton.offscreen = addAddressButton.offscreen
        }

        AddFieldButton {
            id: addAddressButton

            x: parent.width - width - Theme.paddingMedium
            text: root.fieldAdditionText
            icon.source: root.fieldAdditionIcon
            showIconWhenOffscreen: model.index === 0
            offscreen: model.value.length > 0
            animate: root.ready
            highlighted: down || addressHeaderButton.containsPress

            onClicked: {
                offscreen = true
                addressDelegate.forceActiveFocus(animationDuration)
            }

            onEnteredButtonMode: {
                root.resetField(model.index)
            }
        }

        Label {
            id: addressHeaderLabel

            x: addAddressButton.x + addAddressButton.width
            width: parent.width - addAddressButton.offscreenPeekWidth
            height: addAddressButton.height

            text: ContactsUtil.getNameForDetailType(Person.AddressType)
            color: addAddressButton.highlighted ? Theme.highlightColor : Theme.primaryColor
            verticalAlignment: Text.AlignVCenter
            opacity: addAddressButton.offscreen ? 1 : 0

            Behavior on opacity { FadeAnimator {} }

            MouseArea {
                id: addressHeaderButton

                width: parent.implicitWidth
                height: addAddressButton.height

                onClicked: {
                    addressDelegate.forceActiveFocus()
                }
            }
        }

        IconButton {
            id: clearButton

            anchors {
                right: addressHeaderLabel.right
                rightMargin: Theme.paddingMedium
                verticalCenter: addAddressButton.verticalCenter
            }

            icon.source: "image://theme/icon-m-input-remove"
            opacity: addressHeaderLabel.opacity

            onClicked: {
                addressDelegate.aboutToDelete = true
                root.detailModel.userModified = true
                root.detailModel.setProperty(model.index, "value", "")
                addressDelegate.addressFields.clearAllFields()
                root.hasContent = false

                if (!root.animateAndRemove(model.index, addressDelegate, addAddressButton.animationDuration)) {
                    addAddressButton.offscreen = false
                }

                root.hasContent = root._testHasAddressContent()
            }
        }

        Column {
            id: addressFieldsColumn

            y: addAddressButton.height
            width: parent.width
            height: addAddressButton.offscreen ? implicitHeight : 0
            opacity: addAddressButton.offscreen ? 1 : 0
            enabled: addAddressButton.offscreen
            clip: !addAddressButton.busy

            Behavior on opacity {
                FadeAnimator {
                    duration: addAddressButton.animationDuration
                }
            }
            Behavior on height {
                NumberAnimation {
                    duration: addAddressButton.animationDuration
                    easing.type: Easing.InOutQuad
                }
            }

            Row {
                id: addressButtons

                x: addressHeaderLabel.x
                width: parent.width - (addAddressButton.busy ? 0 : x)   // avoid MiniComboBox auto-width-resize while animating
                spacing: Theme.paddingMedium

                MiniComboBox {
                    id: detailSubTypeCombo

                    menu: DetailSubTypeMenu {
                        id: detailSubTypeMenu

                        model: root.detailSubTypeModel
                        currentSubType: addressDelegate.addressSubType

                        onCurrentIndexChanged: detailSubTypeCombo.currentIndex = currentIndex
                        onSubTypeClicked: root.setDetailType(addressDelegate.addressIndex, type, subType)
                    }
                }

                MiniComboBox {
                    id: detailLabelCombo

                    value: (currentItem == null || currentIndex === 0)
                           ? noSelectLabel.text
                           : currentItem.text

                    menu: DetailLabelMenu {
                        id: detailLabelMenu

                        currentLabel: addressDelegate.addressLabel

                        onCurrentIndexChanged: detailLabelCombo.currentIndex = currentIndex
                        onLabelClicked: root.setDetailLabel(addressDelegate.addressIndex, label)
                    }

                    onClicked: focus = true

                    // Dummy to get the label width calculation (cannot use TextMetrics::width, does not update binding as expected)
                    Label {
                        id: noSelectLabel
                        visible: false
                        text: ContactsUtil.getSelectLabelText()
                    }
                }
            }

            Item {
                width: 1
                height: Theme.paddingMedium
            }

            // Repeater of individual address fields (street, city etc.)
            Repeater {
                id: addressFieldsRepeater

                model: addressDelegate.addressFields

                delegate: EditorFieldDelegate {
                    leftMargin: addressHeaderLabel.x
                    buttonMode: false
                    editor: root

                    onModified: {
                        if (addressDelegate.aboutToDelete) {
                            return
                        }

                        var wasEmpty = (model.value.length === 0 && addressFields.allFieldsEmpty())
                        addressFields.setProperty(index, "value", root.detailModel.rightTrim(value))

                        // Add an empty field to act as the next 'Add address' button.
                        if (wasEmpty && value.length > 0 && addressDelegate.addressIndex === root.detailModel.count - 1) {
                            root.addEmptyField()
                        }

                        root.hasContent = value.length > 0 || root._testHasAddressContent()
                    }
                }
            }
        }
    }
}
