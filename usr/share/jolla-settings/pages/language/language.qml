import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.settings.system 1.0
import org.nemomobile.systemsettings 1.0

LanguagePickerPage {
    id: root

    onLanguageClicked: {
        if (languageModel.locale(languageModel.currentIndex) !== locale) {
            openLanguageChangeDialog(language, locale)
        } else {
            pageStack.pop()
        }
    }

    Component {
        id: dialogComponent
        Dialog {
            id: dialog
            property string targetLanguage

            acceptDestination: Dialog {}

            Column {
                anchors.fill: parent

                DialogHeader {
                    dialog: dialog
                }

                Label {
                    font.pixelSize: Theme.fontSizeExtraLarge
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2*Theme.horizontalPageMargin
                    //: %1 is target language
                    //% "Change language and region to %1?"
                    text: qsTrId("settings_system-la-change_language_confirmation").arg(dialog.targetLanguage)
                    wrapMode: Text.Wrap
                    color: Theme.highlightColor
                }

                Item {
                    width: 1
                    height: Theme.paddingLarge
                }

                Label {
                    font.pixelSize: Theme.fontSizeExtraSmall
                    //% "Device will need to reboot and thus be unusable for a while."
                    text: qsTrId("settings_system-la-reboot_warning")
                    wrapMode: Text.Wrap
                    width: parent.width - 2*Theme.horizontalPageMargin
                    x: Theme.horizontalPageMargin
                    color: Theme.highlightColor
                }
            }
        }
    }

    function openLanguageChangeDialog(language, locale) {
        var obj = pageStack.animatorPush(dialogComponent, {targetLanguage: language})
        obj.pageCompleted.connect(function(dialog) {
            dialog.accepted.connect(function() {
                updateAndRebootAnimation.locale = locale
                updateAndRebootAnimation.start()
            })
        })
    }
    SequentialAnimation {
        id: updateAndRebootAnimation
        property string locale
        FadeAnimation {
            duration: 600
            target: fadeOutRectangle
            to: 1.0
        }
        ScriptAction {
            script: root.languageModel.setSystemLocale(updateAndRebootAnimation.locale, LanguageModel.UpdateAndReboot)
        }
    }
    Rectangle {
        id: fadeOutRectangle
        parent: __silica_applicationwindow_instance
        anchors.fill: parent
        color: "black"
        opacity: 0.0
    }
}
