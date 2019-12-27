import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Contacts 1.0
import org.nemomobile.contacts 1.0

DetailModel {
    id: root

    property string valueField
    property bool subTypesExclusive

    function reload(multiTypeDetails) {
        clear()

        for (var i = 0; i < multiTypeDetails.length; ++i) {
            var detail = multiTypeDetails[i]

            var type = detail['type']
            var label = detail['label']
            var value = detail[valueField]
            var subType
            if (!subTypesExclusive) {
                subType = ContactsUtil.getPrimarySubType(type, detail['subTypes'])
            } else {
                subType = detail['subType']
            }
            var nameForDetailType = ContactsUtil.getNameForDetailSubType(type, subType, undefined, true)

            // ListModel does not add the given key-value to the model at all if value=undefined,
            // so use Person.NoSubType or Person.NoLabel if this is the case.
            var properties = {
                "type": type,
                "subType": subType === undefined ? Person.NoSubType : subType,
                "label": label === undefined ? Person.NoLabel : label,
                "name": nameForDetailType,
                "value": value,
                "sourceIndex": detail['index']
            }
            append(properties)
        }
    }

    function getModifiedDetails(originalDetails, ignoredType) {
        var modifiedDetails = []
        for (var i = 0; i < count; i++) {
            var modified = get(i)
            if (modified.type === ignoredType) {
                continue
            }

            var index = modified['sourceIndex']
            var properties = (index == -1 ? {} : originalDetails[index])

            var subType = modified['subType']
            if (!subTypesExclusive) {
                var subTypes = properties['subTypes']
                if (ContactsUtil.isArray(subTypes)) {
                    var primary = ContactsUtil.getPrimarySubType(properties['type'], subTypes)
                    var j
                    for (j = 0; j < subTypes.length; ++j) {
                        if (subTypes[j] == primary) {
                            subTypes[j] = subType
                            break
                        }
                    }
                    if (j == subTypes.length) {
                        subTypes.push(subType)
                    }
                } else {
                    subTypes = [ subType ]
                }
                properties['subTypes'] = subTypes
            } else {
                properties['subType'] = subType
            }

            properties['type'] = modified['type']
            properties['label'] = modified['label']
            properties[valueField] = modified['value']

            modifiedDetails.push(properties)
        }

        return modifiedDetails
    }

    function copyMultiTypeDetailChanges(contact, propertyAccessor, ignoredType) {
        if (!userModified) {
            return
        }

        // Copy all multi-type details to the contact.
        contact[propertyAccessor] = getModifiedDetails(contact[propertyAccessor], ignoredType)
    }
}
