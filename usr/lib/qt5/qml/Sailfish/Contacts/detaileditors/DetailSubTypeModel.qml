import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Contacts 1.0
import org.nemomobile.contacts 1.0

ListModel {
    id: root

    property int defaultType: -1
    property int defaultSubType: -1
    property bool subTypesExclusive

    function reload(allowedTypes, allowedSubTypes) {
        clear()

        for (var i = 0; i < allowedTypes.length; i++) {
            var type = allowedTypes[i]
            var subTypes = allowedSubTypes ? allowedSubTypes[type] : undefined
            var nameForDetailType = ContactsUtil.getNameForDetailType(type)
            if (subTypes == undefined) {
                append({
                    "type": type,
                    "name": nameForDetailType
                })
            } else {
                // Add a Person.NoSubType option.
                append({
                    "type": type,
                    "subType": Person.NoSubType,
                    "name": nameForDetailType
                })
                for (var j = 0; j < subTypes.length; j++) {
                    nameForDetailType = ContactsUtil.getNameForDetailSubType(type, subTypes[j], undefined, true)
                    append({
                        "type": type,
                        "subType": subTypes[j],
                        "name": nameForDetailType
                    })
                }
            }
        }

        if (count > 0) {
            var detail = get(0)
            defaultType = detail.type
            var subType = subTypesExclusive
                    ? detail.subType
                    : ContactsUtil.getPrimarySubType(detail.type, detail.subTypes)
            defaultSubType = subType === undefined ? Person.NoSubType : subType
        }

    }
}
