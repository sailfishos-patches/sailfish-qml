import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.WebView 1.0
import Sailfish.WebEngine 1.0
import Sailfish.WebView.Popups 1.0
import com.jolla.settings.accounts 1.0

Dialog {
    id: root

    property string legaleseText
    property string externalUrlText
    property string externalUrlLink
    property alias userAgent: termsView.httpUserAgent

    DialogHeader {
        id: header
        //: The "accept terms / data usage" dialog header
        //% "Consent"
        acceptText: qsTrId("jolla_settings_accounts_extensions-he-consent")
    }

    SilicaFlickable {
        id: flick
        anchors {
            top: header.bottom
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }
        clip: true
        contentHeight: consentLabel.height + termsButton.anchors.topMargin + termsButton.height + Theme.paddingLarge

        VerticalScrollDecorator {}

        Label {
            id: consentLabel
            width: parent.width - x*2
            x: Theme.horizontalPageMargin
            color: Theme.highlightColor
            text: root.legaleseText
            wrapMode: Text.Wrap
            textFormat: Text.AutoText
            font.pixelSize: Theme.fontSizeSmall
        }

        Button {
            id: termsButton
            anchors {
                top: consentLabel.bottom
                topMargin: Theme.paddingLarge*2
                horizontalCenter: consentLabel.horizontalCenter
            }
            text: root.externalUrlText
            preferredWidth: Theme.buttonWidthLarge

            onClicked: {
                flick.visible = false
                consentLabel.visible = false
                termsButton.visible = false
                termsView.visible = true
            }
        }
    }

    WebView {
        id: termsView
        visible: false
        url: root.externalUrlLink
        privateMode: true
        anchors {
            topMargin: -Theme.paddingLarge
            top: header.bottom
            bottom: root.bottom
            left: root.left
            right: root.right
        }

        Component.onCompleted: {
            WebEngineSettings.popupEnabled = false
        }

        popupProvider: PopupProvider {
            // Disable the Save Password dialog
            passwordManagerPopup: null
        }
    }
}
