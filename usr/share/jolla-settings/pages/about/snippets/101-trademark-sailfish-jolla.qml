import QtQuick 2.1
import Sailfish.Silica 1.0
import com.jolla.settings.system 1.0

Column {
    spacing: Theme.paddingLarge

    AboutText {
        //% "Jolla and Sailfish are trademarks or registered trademarks of Jollyboys Ltd. ('Our'). Our product names are either our trademarks or registered trademarks. Our Software is protected by copyright, trademark, trade secrets and other intellectual property rights."
        text: qsTrId("settings_about-la-jolla_trademarks")
    }
}
