import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.contacts 1.0

Column {
    width: parent.width
    property alias checked: textSwitch.checked
    property alias text: textSwitch.text
    property alias busy: textSwitch.busy
    property bool systemValue
    property bool changed: systemValue != checked

    onSystemValueChanged: checked = systemValue

    function reset() {
        checked = systemValue
    }

    TextSwitch {
        id: textSwitch
        enabled: parent.enabled
    }
}
