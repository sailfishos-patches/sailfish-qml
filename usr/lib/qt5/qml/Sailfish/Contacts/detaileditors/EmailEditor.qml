import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.contacts 1.0

MultiTypeFieldEditor {
    //: Add an email for this contact
    //% "Add email"
    fieldAdditionText: qsTrId("contacts-bt-contact_add_email")
    fieldAdditionIcon: "image://theme/icon-m-mail"

    propertyAccessor: 'emailDetails'
    valueField: 'address'
    allowedTypes: [ Person.EmailAddressType ]
    canChangeFieldType: false

    inputMethodHints: Qt.ImhEmailCharactersOnly
    prepopulate: true
}
