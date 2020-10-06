import QtQuick 2.1
import QtQuick.Window 2.1
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0
import Nemo.Ngf 1.0
import Nemo.DBus 2.0

SystemDialogWindow {
    id: window
    category: SystemDialogWindow.Alarm

    property alias text: label.text
    property var properties

    function activate() {
        mce.notificationBeginReq()
        feedback.play()
        showFullScreen()
        raise()
    }

    function dismiss() {
        mce.notificationEndReq()
        lower()
    }

    NonGraphicalFeedback {
        id: feedback

        event: "sms"
    }

    DBusInterface {
        id: mce

        bus: DBus.SystemBus
        service: "com.nokia.mce"
        path: "/com/nokia/mce/request"
        iface:  "com.nokia.mce.request"

        function notificationBeginReq() {
            typedCall("notification_begin_req", [
                { "type": "s", "value": "cell_broadcast_message" },
                { "type": "i", "value": 10000 },
                { "type": "i", "value": 0 }])
        }
        function notificationEndReq() {
            typedCall("notification_end_req", [
                { "type": "s", "value": "cell_broadcast_message" },
                { "type": "i", "value": 0 }])
        }
    }

    ApplicationWindow {
        // ApplicationWindow isn't really designed for multiple instantiations.
        id: __silica_applicationwindow_instance

        _defaultLabelFormat: Text.PlainText
        cover: undefined
        initialPage: Page {
            id: page

            SilicaFlickable {
                id: flickable

                anchors.fill: parent
                contentHeight: Math.max(page.height, topDismissIcon.height +
                        title.height + label.paintedHeight + bottomDismissIcon.height +
                        5 * Theme.paddingLarge)

                PulleyAnimationHint {
                    pullDownDistance: Theme.itemSizeLarge + Theme.itemSizeExtraSmall
                    anchors.fill: parent
                }

                PullDownMenu {
                    quickSelect: true
                    bottomMargin: Theme.itemSizeExtraSmall
                    MenuItem {
                        //% "Dismiss"
                        text: qsTrId("voicecall-la-me_dismiss")
                        onClicked: dismiss()
                    }
                }

                PushUpMenu {
                    quickSelect: true
                    topMargin: Theme.itemSizeExtraSmall
                    MenuItem {
                        //% "Dismiss"
                        text: qsTrId("voicecall-la-me_dismiss")
                        onClicked: dismiss()
                    }
                }

                Image {
                    id: topDismissIcon

                    y: Theme.paddingLarge
                    anchors.horizontalCenter: parent.horizontalCenter
                    source: "image://theme/icon-l-dismiss?" + Theme.highlightColor
                }

                Label {
                    id: title

                    anchors {
                        top: topDismissIcon.bottom
                        topMargin: Theme.paddingLarge
                        horizontalCenter: parent.horizontalCenter
                    }
                    width: parent.width - 2*Theme.horizontalPageMargin
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Theme.fontSizeExtraLarge
                    wrapMode: Text.Wrap
                    //: Cell broadcast page title
                    //% "Broadcast message"
                    text: qsTrId("voicecall-la-cbs_title")
                }

                Item {
                    anchors {
                        top: title.bottom
                        bottom: bottomDismissIcon.top
                        left: parent.left
                        right: parent.right
                    }

                    Label {
                        id: label

                        width: parent.width - 2*Theme.horizontalPageMargin
                        height: parent.height - 2*Theme.paddingLarge
                        anchors.centerIn: parent
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        minimumPixelSize: Theme.fontSizeMedium
                        font.pixelSize: Theme.fontSizeLarge
                        fontSizeMode: Text.VerticalFit
                    }
                }

                Image {
                    id: bottomDismissIcon

                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        bottom: parent.bottom
                        bottomMargin: Theme.paddingLarge
                    }
                    source: "image://theme/icon-l-dismiss?" + Theme.highlightColor
                }
            }
        }
    }
}
