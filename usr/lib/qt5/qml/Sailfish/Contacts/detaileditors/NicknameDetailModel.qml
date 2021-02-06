import QtQuick 2.5

MultiTypeDetailModel {
    id: nicknameModel

    property var contact
    readonly property string propertyAccessor: "nicknameDetails"

    function findNicknameWithSourceIndex(sourceIndex) {
        for (var i = 0; i < count; ++i) {
            if (get(i).sourceIndex === sourceIndex) {
                return i
            }
        }
        return -1
    }

    valueField: "nickname"
    subTypesExclusive: false

    onContactChanged: {
        if (contact) {
            nicknames.reload(contact[nicknames.propertyAccessor])
        }
    }
}
