import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0

Page {
    property var importFromFile
    property var abandonImport

    SilicaFlickable {
        id: flickable
        width: parent.width
        height: parent.height
        contentWidth: width
        contentHeight: actionColumn.y + actionColumn.height + Theme.paddingMedium

        Column {
            id: contentColumn
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader {
                //: Other phones heading
                //% "Other phone"
                title: qsTrId("contacts-he-other_phones")
            }
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - x - Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                color: Theme.highlightColor
                font { pixelSize: Theme.fontSizeMedium }

                //: Prompt the user to choose an import option (text should match import button label)
                //% "If you can't or don't want to use service synchronization from your old phone, you can either transfer your contacts via SIM card or by creating a contacts file and transferring that to your device. If you already have one or more vCard files on your device or a memory card, choose 'Import from file'."
                text: qsTrId("contacts-la-import_other_prompt")
            }
            LinkButton {
                leftMargin: Theme.horizontalPageMargin
                rightMargin: Theme.horizontalPageMargin

                link: learnMoreLink.value
                      ? learnMoreLink.value
                      : 'https://jolla.zendesk.com/hc/en-us/articles/201836827'

                // Link to detailed instructions on Jolla website
                //% "Learn More"
                text: qsTrId("contacts-bt-import_learn_more")
            }
        }

        ButtonLayout {
            id: actionColumn

            // Position buttons at the bottom of the page
            y: Math.max(flickable.height - (height + Theme.itemSizeMedium), contentColumn.y + contentColumn.height + Theme.paddingLarge)
            preferredWidth: Theme.buttonWidthMedium

            Button {
                //: Import from file
                //% "Import from file"
                text: qsTrId("contacts-bt-import_from_file")

                onClicked: importFromFile()
            }
            Button {
                ButtonLayout.newLine: true

                //: Cancel import procedure
                //% "Skip importing"
                text: qsTrId("contacts-bt-skip_importing")

                onClicked: abandonImport()
            }
        }
    }

    ConfigurationValue {
        id: learnMoreLink
        key: "/desktop/help-articles/import_learn_more_link"
    }

}
