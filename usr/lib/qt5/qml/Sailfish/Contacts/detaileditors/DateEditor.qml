import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Contacts 1.0
import org.nemomobile.contacts 1.0

MultiTypeFieldEditor {
    id: root

    property int _dummyBirthdaySubType: -9999

    // override BaseEditor testHasContent()
    function testHasContent(listModel) {
        listModel = listModel || detailModel
        for (var i = 0; i < listModel.count; ++i) {
            var value = listModel.get(i).value
            if (!isNaN(value.getTime())) {
                return true
            }
        }
        return false
    }

    function populateFieldEditor() {
        detailModel.emptyValue = new Date(Number.NaN)

        // Add dates from Person::anniversaryDetails.
        detailModel.reload(contact[propertyAccessor])

        // Add birthday from Person::birthday.
        if (!isNaN(contact.birthday)) {
            var properties = {
                "type": Person.BirthdayType,
                "subType": _dummyBirthdaySubType,
                "name": ContactsUtil.getNameForDetailType(Person.BirthdayType),
                "value": contact.birthday,
                "sourceIndex": -1
            }
            // Show birthday before other date values.
            detailModel.insert(0, properties)
        }

        // Add sub-type options for dates by combining anniversary sub-types with an extra
        // 'birthday' type. To prevent the user from setting more than one data as a birthday,
        // use two models for the date type combo menus: one with 'Birthday', and one without,
        // and show the correct one  depending on whether a birthday has already been selected.
        detailSubTypeModel.reload(allowedTypes, allowedSubTypes)
        detailSubTypeModelWithBirthday.reload(allowedTypes, allowedSubTypes)
        detailSubTypeModelWithBirthday.insert(1, {
            "type": Person.BirthdayType,
            "subType": _dummyBirthdaySubType,
            "name": ContactsUtil.getNameForDetailType(Person.BirthdayType)
        })

        // Add an empty field to act as the 'Add date' button.
        addEmptyField()
    }

    function aboutToSave() {
        if (detailModel.userModified) {
            // Copy birthday value to Person::birthday.
            var birthdayIndex = _birthdayFieldIndex()
            contact.birthday = birthdayIndex >= 0 ? detailModel.get(birthdayIndex).value : detailModel.emptyValue

            // Copy non-birthday dates from detailModel to Person::anniversaryDetails.
            detailModel.copyMultiTypeDetailChanges(contact, propertyAccessor, Person.BirthdayType)
        }
    }

    function _changeDate(fieldIndex, currentValue) {
        focus = true    // close vkb if open
        var obj = pageStack.animatorPush("Sailfish.Silica.DatePickerDialog", { date: currentValue })
        obj.pageCompleted.connect(function(dialog) {
            dialog.accepted.connect(function() {
                var wasEmpty = isNaN(currentValue)
                root.detailModel.userModified = true
                var delegate = root.detailEditors.itemAt(fieldIndex)
                if (!!delegate) {
                    delegate.exitButtonMode()
                }
                root.detailModel.setProperty(fieldIndex, "value", dialog.date)

                // Add an empty field to act as the next 'Add date' button.
                if (wasEmpty && fieldIndex === root.detailModel.count - 1) {
                    root.addEmptyField()
                }
            })
        })
    }

    function _birthdayFieldIndex() {
        for (var i = 0; i < detailEditors.count; ++i) {
            if (detailEditors.itemAt(i).isBirthday) {
                return i
            }
        }
        return -1
    }

    function _addEmptyDate(fieldIndex) {
        var delegate = root.detailEditors.itemAt(fieldIndex)
        if (!!delegate) {
            delegate.exitButtonMode()
        }

        // Assign 'birthday' type if no other date is currently set as birthday
        root.detailModel.setProperty(fieldIndex,
                                     "type",
                                     _birthdayFieldIndex() < 0 ? Person.BirthdayType : Person.AnniversaryType)
    }

    //: Add a date (e.g. a wedding anniversary date) for this contact
    //% "Add date"
    fieldAdditionText: qsTrId("contacts-bt-contact_add_date")
    fieldAdditionIcon: "image://theme/icon-m-date"

    propertyAccessor: 'anniversaryDetails'
    valueField: 'originalDate'
    allowedTypes: [ Person.AnniversaryType ]
    subTypesExclusive: true
    allowedSubTypes: {
        var subTypes = {}
        subTypes[Person.AnniversaryType] = [
            Person.AnniversarySubTypeWedding,
            Person.AnniversarySubTypeEngagement,
            Person.AnniversarySubTypeHouse,
            Person.AnniversarySubTypeEmployment,
            Person.AnniversarySubTypeMemorial
        ]
        return subTypes
    }

    canChangeLabelType: false

    fieldDelegate: Item {
        id: dateDelegate

        readonly property int dateIndex: model.index
        readonly property int isBirthday: model.type === Person.BirthdayType
        readonly property int dateSubType: model.subType

        function exitButtonMode() {
            addDateButton.offscreen = true
        }

        width: parent.width
        height: addDateButton.offscreen ? dateDisplay.height : addDateButton.height

        Component.onCompleted: {
            if (!isNaN(model.value)) {
                exitButtonMode()
            }
        }

        Behavior on height {
            enabled: root.populated

            NumberAnimation {
                duration: root.animationDuration
                easing.type: Easing.InOutQuad
            }
        }

        AddFieldButton {
            id: addDateButton

            x: parent.width - width - Theme.paddingMedium
            text: root.fieldAdditionText
            icon.source: root.fieldAdditionIcon
            showIconWhenOffscreen: model.index === 0
            animate: root.ready
            opacity: enabled ? 1 : 0
            highlighted: down || dateLabelMouseArea.containsPress

            onClicked: {
                root._addEmptyDate(model.index)
            }

            onEnteredButtonMode: {
                root.resetField(model.index)
            }
        }

        Item {
            id: dateDisplay

            x: addDateButton.x + addDateButton.width - addDateButton.offscreenPeekWidth
            width: parent.width - x
            height: dateTypeCombo.y + dateTypeCombo.height + Theme.paddingMedium

            enabled: addDateButton.offscreen
            opacity: addDateButton.revealedContentOpacity

            Label {
                id: dateLabel

                x: addDateButton.offscreenPeekWidth
                y: addDateButton.height/2 - height/2
                width: parent.width - x - clearButton.width

                text: ContactsUtil.getDateButtonText(Format, model.value)
                color: addDateButton.highlighted ? Theme.highlightColor : Theme.primaryColor
                truncationMode: TruncationMode.Fade

                MouseArea {
                    id: dateLabelMouseArea
                    anchors {
                        fill: parent
                        margins: -Theme.paddingMedium
                    }

                    onClicked: root._changeDate(model.index, model.value)
                }
            }

            IconButton {
                id: clearButton

                anchors {
                    right: parent.right
                    rightMargin: Theme.paddingMedium
                    verticalCenter: dateLabel.verticalCenter
                }
                icon.source: "image://theme/icon-m-input-remove"

                onClicked: {
                    root.detailModel.userModified = true
                    if (!root.animateAndRemove(model.index, dateDelegate)) {
                        addDateButton.offscreen = false
                        root.detailModel.setProperty(model.index, "value", root.detailModel.emptyValue)
                    }
                }
            }

            MiniComboBox {
                id: dateTypeCombo

                x: dateLabel.x
                y: addDateButton.height - Theme.paddingSmall

                menu: DetailSubTypeMenu {
                    model: dateDelegate.isBirthday
                           ? detailSubTypeModelWithBirthday
                           : root.detailSubTypeModel
                    currentSubType: dateDelegate.isBirthday
                                    ? _dummyBirthdaySubType
                                    : dateDelegate.dateSubType

                    onCurrentIndexChanged: {
                        dateTypeCombo.currentIndex = currentIndex
                    }

                    onSubTypeClicked: {
                        var birthdaySelected = (subType === _dummyBirthdaySubType)
                        root.setDetailType(dateDelegate.dateIndex, type, birthdaySelected ? Person.NoSubType : subType)
                    }
                }
            }
        }
    }

    DetailSubTypeModel {
        id: detailSubTypeModelWithBirthday
    }
}

