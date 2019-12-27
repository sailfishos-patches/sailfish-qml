import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.contacts 1.0

MultiTypeFieldEditor {
    //: Add a phone number for this contact
    //% "Add phone"
    fieldAdditionText: qsTrId("contacts-bt-contact_add_phone")
    fieldAdditionIcon: "image://theme/icon-m-answer"

    propertyAccessor: 'phoneDetails'
    valueField: 'number'
    allowedTypes: [ Person.PhoneNumberType ]
    subTypesExclusive: false
    allowedSubTypes: {
        var subTypes = {}
        subTypes[Person.PhoneNumberType] = [
            Person.PhoneSubTypeAssistant,
            Person.PhoneSubTypeFax,
            Person.PhoneSubTypePager,
            Person.PhoneSubTypeVideo,
            Person.PhoneSubTypeMobile
        ]
        return subTypes
    }

    inputMethodHints: Qt.ImhDialableCharactersOnly
    prepopulate: true
}
