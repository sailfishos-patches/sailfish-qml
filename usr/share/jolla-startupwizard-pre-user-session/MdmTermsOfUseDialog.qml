import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.startupwizard 1.0
import Sailfish.Mdm 1.0
import org.nemomobile.systemsettings 1.0

Dialog {
    id: root

    property string localeName
    property StartupWizardManager startupWizardManager

    acceptDestinationAction: PageStackAction.Replace
    acceptDestinationReplaceTarget: null

    MdmTermsOfUse {
        id: mdmTerms
    }

    Flickable {
        id: flickable

        anchors.fill: parent
        contentHeight: dialogHeader.height + contentColumn.height

        DialogHeader {
            id: dialogHeader
            dialog: root

            cancelText: startupWizardManager.translatedText("startupwizard-he-previous_page", root.localeName)  // translation string defined in WizardDialogHeader
            acceptText: startupWizardManager.translatedMdmText(mdmTerms.translationIds["triggerAccept"], root.localeName)
        }

        Column {
            id: contentColumn

            anchors.top: dialogHeader.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 2*Theme.paddingLarge
            spacing: Theme.paddingLarge

            Label {
                id: headerLabel

                width: parent.width
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraLarge
                color: startupWizardManager.defaultHighlightColor()
                text: startupWizardManager.translatedMdmText(mdmTerms.translationIds["title"], root.localeName)
                    .arg(aboutSettings.baseOperatingSystemName)
            }

            Label {
                width: parent.width
                wrapMode: Text.Wrap
                color: startupWizardManager.defaultHighlightColor()
                text: startupWizardManager.translatedMdmText(mdmTerms.translationIds["summary"], root.localeName)
            }

            Label {
                width: parent.width
                wrapMode: Text.Wrap
                color: startupWizardManager.defaultHighlightColor()
                text: startupWizardManager.translatedMdmText(mdmTerms.translationIds["body"], root.localeName)
            }
        }
    }

    AboutSettings {
        id: aboutSettings
    }
}
