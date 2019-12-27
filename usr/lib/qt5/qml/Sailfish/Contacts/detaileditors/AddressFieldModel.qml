import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Contacts 1.0
import org.nemomobile.contacts 1.0

ListModel {
    id: root

    function reload(addressString) {
        clear()

        var addressData = addressString.length === 0 ? "" : ContactsUtil.addressStringToMap(addressString)
        for (var i = 0; i < ContactsUtil.addressFields.length; ++i) {
            var fieldType = ContactsUtil.addressFields[i]
            var fieldValue = addressString.length === 0 ? "" : addressData[fieldType]
            append({
                "type": fieldType,
                "name": ContactsUtil.getDescriptionForDetail(Person.AddressType, fieldType),
                "value": fieldValue,
                "inputMethodHints": ContactsUtil.getInputMethodHintsForDetail(Person.AddressType, fieldType)
            })
        }
    }

    function allFieldsEmpty() {
        for (var i = 0; i < count; i++) {
            if (get(i).value.length > 0) {
                return false
            }
        }
        return true
    }

    function clearAllFields() {
        for (var i = 0; i < count; i++) {
            setProperty(i, "value", "")
        }
    }

    function editedAddressAsString() {
        var addressData = {}
        var i
        for (i = 0; i < count; i++) {
            var data = get(i)
            addressData[data.type] = data.value
        }
        var saveOrder = ContactsUtil.addressFields
        var ret = []
        for (i = 0; i < saveOrder.length; i++) {
            var value = addressData[saveOrder[i]]
            if (value === undefined) {
                value = ""
            }
            ret.push(value)
        }
        return ret.join("\n")
    }

}
