import QtQuick 2.1
import Sailfish.Silica 1.0
import com.jolla.settings.system 1.0

Column {
    spacing: Theme.paddingLarge

    function _showEula(translatedText) {
        if (translatedText.length === 2) {
            var props = {
                "headingText": translatedText[0],
                "bodyText": translatedText[1]
            }
            pageStack.animatorPush(fullTermsComponent, props)
        } else {
            console.warn("Could not load translated EULA.")
        }
    }

    function showPlatformEula() {
        var translatedText = termsOfUseManager.platformTermsOfUse(Qt.locale().name)
        _showEula(translatedText)
    }

    function showVendorEula() {
        var translatedText = termsOfUseManager.vendorTermsOfUse(Qt.locale().name)
        _showEula(translatedText)
    }

    TermsOfUseManager {
        id: termsOfUseManager
    }

    AboutText {
        //: Text surrounded by %1 and %2 is underlined and colored differently
        //% "By using this device you have accepted %1The Sailfish OS End User License Agreement%2."
        text: qsTrId("settings_about-la-platform_eula")
                    .arg("<u><font color=\"" + (platformEulaMouseArea.pressed ? Theme.highlightColor : Theme.primaryColor) + "\">")
                    .arg("</font></u>")

        MouseArea {
            id: platformEulaMouseArea
            anchors.fill: parent
            onClicked: showPlatformEula()
        }
    }

    // TODO: Add mechanism for finding the vendor terms. Until then this will not show up.
    // NOTE: We agreed to implement that when there is a customer need. Will stay as-is until then.
    AboutText {
        property var vendorTermsSummary: visible ? termsOfUseManager.vendorTermsSummary(Qt.locale().name) : ""

        visible: termsOfUseManager.hasVendorTermsOfUse
        text: "<u><font color=\"" + (vendorEulaMouseArea.pressed ? Theme.highlightColor : Theme.primaryColor) + "\">" +
              vendorTermsSummary[0] +
              "</font></u> " +
              vendorTermsSummary[1]

        MouseArea {
            id: vendorEulaMouseArea
            anchors.fill: parent
            onClicked: showVendorEula()
        }
    }

    Component {
        id: fullTermsComponent

        Page {
            property alias headingText: header.title
            property alias bodyText: bodyTextLabel.text

            SilicaFlickable {
                anchors.fill: parent
                contentHeight: header.height + termsTextColumn.height + (Theme.paddingLarge * 2)

                PageHeader {
                    id: header
                    wrapMode: Text.Wrap
                }

                Column {
                    id: termsTextColumn
                    anchors {
                        top: header.bottom
                        left: parent.left
                        leftMargin: Theme.horizontalPageMargin
                        right: parent.right
                        rightMargin: Theme.horizontalPageMargin
                    }
                    spacing: Theme.paddingLarge

                    Label {
                        id: bodyTextLabel
                        width: parent.width
                        wrapMode: Text.Wrap
                        font.pixelSize: Theme.fontSizeExtraSmall
                        color: Theme.highlightColor
                    }
                }

                VerticalScrollDecorator {}
            }
        }
    }

}
