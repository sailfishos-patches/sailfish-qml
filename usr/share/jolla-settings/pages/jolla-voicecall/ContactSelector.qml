import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Contacts 1.0
import org.nemomobile.contacts 1.0

ContactSelectPage {
    id: contactSelectorPage
    signal numberSelected(string number)

    requiredProperty: PeopleModel.PhoneNumberRequired

    onContactClicked: numberSelected(property.number)
}
