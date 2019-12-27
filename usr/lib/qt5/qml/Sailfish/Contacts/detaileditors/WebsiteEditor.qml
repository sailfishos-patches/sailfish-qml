import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.contacts 1.0

MultiTypeFieldEditor {
    //: Add a website for this contact
    //% "Add website"
    fieldAdditionText: qsTrId("contacts-bt-contact_add_website")
    fieldAdditionIcon: "image://theme/icon-m-website"

    propertyAccessor: 'websiteDetails'
    valueField: 'url'
    allowedTypes: [ Person.WebsiteType ]
    subTypesExclusive: true
    allowedSubTypes: {
        var subTypes = {}
        subTypes[Person.WebsiteType] = [
            Person.WebsiteSubTypeHomePage,
            Person.WebsiteSubTypeBlog,
            Person.WebsiteSubTypeFavorite
        ]
        return subTypes
    }

    inputMethodHints: Qt.ImhUrlCharactersOnly
}
