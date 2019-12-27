import QtQuick 2.1
import Sailfish.Silica 1.0
import com.jolla.settings.system 1.0

Column {
    spacing: Theme.paddingLarge

    AboutText {
        //% "Jolla and Sailfish are trademarks or registered trademarks of Jolla Ltd. Jolla's product names are either trademarks or registered trademarks of Jolla. Jolla’s software is protected by copyright, trademark, trade secrets and other intellectual property rights of Jolla and its licensors."
        text: qsTrId("settings_about-la-jolla_trademark_notification")
    }
}
