import QtQuick 2.6
import Sailfish.Silica 1.0
import Nemo.DBus 2.0

Column {
    width: parent.width
    bottomPadding: Theme.paddingSmall

    SectionHeader {
        //% "Text prediction"
        text: qsTrId("settings_text_input-la-text_prediction_section")
    }

    Item {
        width: 1
        height: Theme.paddingSmall
    }

    Button {
        anchors.horizontalCenter: parent.horizontalCenter
        //% "Clear learned words"
        text: qsTrId("settings_text_input-bt-clear_words")
        onClicked: {
            //% "Cleared learned words"
            Remorse.popupAction(root, qsTrId("settings_text_input-la-cleared_words_remorse_banner"),
                            function() {
                                keyboardDbus.call("clearData", undefined)
                            })
        }
    }

    DBusInterface {
        id: keyboardDbus
        service: "com.jolla.keyboard"
        path: "/com/jolla/keyboard"
        iface: "com.jolla.keyboard"
    }
}
