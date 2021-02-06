import QtQuick 2.0

ListModel {
    property bool userModified
    property var emptyValue: ""

    function copySingleTypeDetailChanges(contact, ignoredType) {
        if (!userModified) {
            return
        }

        for (var i = 0; i < count; ++i) {
            var detail = get(i)
            if (detail.type === ignoredType || detail.propertyName.length === 0) {
                continue
            }

            contact[detail.propertyName] = detail.value.trim()
        }
    }
}
