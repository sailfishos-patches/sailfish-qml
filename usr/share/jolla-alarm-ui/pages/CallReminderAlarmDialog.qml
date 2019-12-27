import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.alarmui 1.0
import Nemo.DBus 2.0

AlarmDialogBase {
    onTimeout: closeDialog(AlarmDialogStatus.Closed)

    topIconSource: "image://theme/icon-l-answer"

    PullDownMenu {
        quickSelect: true
        bottomMargin: Theme.itemSizeExtraSmall
        MenuItem {
            //% "Call"
            text: qsTrId("alarm-ui-me-alarm_dialog_call")
            onClicked: {
                voiceCallUi.call("openContactCard", [ alarm.phoneNumber ])
                closeDialog(AlarmDialogStatus.Closed)
            }
        }
    }

    Label {
        width: parent.width
        font {
            pixelSize: Theme.fontSizeHuge
            family: Theme.fontFamilyHeading
        }
        horizontalAlignment: Text.AlignHCenter

        //% "Call back"
        text: qsTrId("alarm-ui-alarm_dialog_call_back")
    }

    Label {
        width: parent.width
        font {
            pixelSize: Theme.fontSizeHuge
            family: Theme.fontFamilyHeading
        }
        horizontalAlignment: Text.AlignHCenter
        maximumLineCount: 3
        text: alarm.title
        wrapMode: Text.Wrap
    }

    Label {
        width: parent.width
        height: implicitHeight + Theme.itemSizeExtraLarge
        font {
            pixelSize: Theme.fontSizeSmall
            family: Theme.fontFamilyHeading
        }

        horizontalAlignment: Text.AlignHCenter
        //% "Call reminder"
        text: qsTrId("alarm-ui-alarm_dialog_call_reminder")
    }

    data: DBusInterface {
        id: voiceCallUi

        service: "com.jolla.voicecall.ui"
        path: "/"
        iface: "com.jolla.voicecall.ui"
    }
}
