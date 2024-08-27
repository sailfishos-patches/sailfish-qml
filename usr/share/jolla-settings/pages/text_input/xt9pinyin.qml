import QtQuick 2.6
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0

Column {
    width: parent.width

    SectionHeader {
        //% "Chinese virtual keyboard"
        text: qsTrId("settings_text_input-la-chinese_virtual_keyboard_section")
    }

    TextSwitch {
        automaticCheck: false
        checked: mohuConfig.value
        //: Aka "mohu"
        //% "Fuzzy pinyin"
        text: qsTrId("settings_text_input-la-fuzzy_pinyin")
        onClicked: mohuConfig.value = !mohuConfig.value
    }

    ConfigurationValue {
        id: mohuConfig

        key: "/sailfish/text_input/mohu_enabled"
        defaultValue: false
    }
}
