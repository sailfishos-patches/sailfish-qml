import QtQuick 2.1
import Sailfish.Silica 1.0
import com.jolla.settings.system 1.0

Column {
    AboutText {
        //: Text surrounded by %1 and %2 is underlined and colored differently
        //% "You can %1see information about packages%2 installed on this system."
        text: qsTrId("settings_package_licenses-la-packages_info")
                    .arg("<u><font color=\"" + (mouseArea.pressed ? Theme.highlightColor : Theme.primaryColor) + "\">")
                    .arg("</font></u>")

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            onClicked: pageStack.animatorPush("com.jolla.settings.system.PackagesPage")
        }
    }
}
