import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.settings.system 1.0
import org.nemomobile.systemsettings 1.0

Page {
    id: root

    function showBundle(type, title)
    {
        certificateModel.bundleType = type
        pageStack.animatorPush("BundlePage.qml", { 'title': title, 'model': certificateModel })
    }

    Column {
        width: parent.width

        PageHeader {
            //% "Certificates"
            title: qsTrId("settings_system-he-certificates")
        }

        Repeater {
            model: bundleModel

            delegate: BackgroundItem {
                id: delegateItem
                width: parent.width
                height: column.height + Theme.paddingMedium*2

                Column {
                    id: column

                    x: Theme.horizontalPageMargin
                    width: parent.width - x*2
                    y: Theme.paddingMedium

                    Label {
                        width: parent.width
                        text: qsTrId(name)
                        color: delegateItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                        wrapMode: Text.Wrap
                    }
                    Label {
                        width: parent.width
                        text: qsTrId(subtitle)
                        font.pixelSize: Theme.fontSizeSmall
                        color: delegateItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                        wrapMode: Text.Wrap
                    }
                }

                onClicked: root.showBundle(type, qsTrId(name))
            }
        }
    }

    function qsTrIdStrings() {
        //% "TLS Certificates"
        QT_TRID_NOOP("settings_system-he-tls_certificates")
        //% "Certificates trusted for TLS authentication"
        QT_TRID_NOOP("settings_system-la-tls_certificates_subtitle")
        //% "Email Certificates"
        QT_TRID_NOOP("settings_system-he-email_certificates")
        //% "Certificates trusted for email protection"
        QT_TRID_NOOP("settings_system-la-email_certificates_subtitle")
        //% "Code Signing Certificates"
        QT_TRID_NOOP("settings_system-he-objsign_certificates")
        //% "Certificates trusted for code signing"
        QT_TRID_NOOP("settings_system-la-objsign_certificates_subtitle")
    }

    ListModel {
        id: bundleModel

        ListElement {
            name: "settings_system-he-tls_certificates"
            subtitle: "settings_system-la-tls_certificates_subtitle"
            type: CertificateModel.TLSBundle
        }
        ListElement {
            name: "settings_system-he-email_certificates"
            subtitle: "settings_system-la-email_certificates_subtitle"
            type: CertificateModel.EmailBundle
        }
        ListElement {
            name: "settings_system-he-objsign_certificates"
            subtitle: "settings_system-la-objsign_certificates_subtitle"
            type: CertificateModel.ObjectSigningBundle
        }
    }

    CertificateModel {
        id: certificateModel
    }
}
