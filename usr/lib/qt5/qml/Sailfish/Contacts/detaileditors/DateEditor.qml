import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Contacts 1.0
import org.nemomobile.contacts 1.0

MultiTypeFieldEditor {
    id: root

    property int _dummyBirthdaySubType: -9999
    property var _birthday

    function populateFieldEditor() {
        detailModel.emptyValue = new Date(Number.Nan)
        _birthday = detailModel.emptyValue

        // Add dates from Person::anniversaryDetails.
        detailModel.reload(contact[propertyAccessor])

        // Add birthday from Person::birthday.
        _birthday = contact.birthday
        if (!isNaN(_birthday)) {
            var properties = {
                "type": Person.BirthdayType,
                "subType": _dummyBirthdaySubType,
                "name": ContactsUtil.getNameForDetailType(Person.BirthdayType),
                "value": _birthday,
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
            contact.birthday = _birthday

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
                if (root.detailModel.get(fieldIndex).type === Person.BirthdayType) {
                    root._birthday = dialog.date
                }

                // Add an empty field to act as the next 'Add date' button.
                if (wasEmpty && fieldIndex === root.detailModel.count - 1) {
                    root.addEmptyField()
                }
            })
        })
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
        readonly property var dateValue: model.value

        function exitButtonMode() {
            addDateButton.offscreen = true
        }

        width: parent.width
        height: addDateButton.offscreen ? dateDisplay.height : addDateButton.height

        AddFieldButton {
            id: addDateButton

            x: parent.width - width - Theme.paddingMedium
            text: root.fieldAdditionText
            icon.source: root.fieldAdditionIcon
            showIconWhenOffscreen: model.index === 0
            offscreen: !isNaN(model.value)
            animate: root.ready
            opacity: enabled ? 1 : 0
            highlighted: down || dateLabelMouseArea.containsPress

            onClicked: {
                root._changeDate(model.index)
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

                    onClicked: root._changeDate(model.index)
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
                    }
                    if (model.type === Person.BirthdayType) {
                        root._birthday = root.detailModel.emptyValue
                    }
                }
            }

            MiniComboBox {
                id: dateTypeCombo

                x: dateLabel.x
                y: addDateButton.height - Theme.paddingSmall

                menu: DetailSubTypeMenu {
                    model: dateDelegate.isBirthday || isNaN(root._birthday)
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
                        if (birthdaySelected) {
                            // This is the new birthday.
                            root._birthday = dateDelegate.dateValue
                        } else if (dateDelegate.isBirthday) {
                            // This was previously set as the birthday, but not anymore.
                            root._birthday = root.detailModel.emptyValue
                        }
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

