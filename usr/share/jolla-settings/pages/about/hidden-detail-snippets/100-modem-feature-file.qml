import QtQuick 2.1
import Sailfish.Silica 1.0
import com.jolla.settings.system 1.0

Item {
    height: content.visible ? content.height : 0

    ModemFeatures {
        id: features
    }

    DetailItem {
        id: content

        visible: value != ""
        //% "Modem firmware variant"
        label: qsTrId("settings_about-la-modem_firmware_variant")
        value: features.variant
    }
}

