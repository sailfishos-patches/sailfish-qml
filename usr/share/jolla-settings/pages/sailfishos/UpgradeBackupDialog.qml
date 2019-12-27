import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Vault 1.0

NewBackupRestoreDialog {
    id: root

    property BackupRestoreStoragePicker storagePicker

    signal continueOSUpdate()

    backupMode: true
    cloudAccountId: storagePicker.cloudAccountId
    backupDir: storagePicker.memoryCardPath

    canAccept: storagePicker.selectionValid
    acceptDestination: backupRestoreProgressComponent

    Component {
        id: backupRestoreProgressComponent

        BackupRestoreProgressPage {
            id: progressPage

            backupMode: true
            cloudAccountId: root.storagePicker.cloudAccountId
            backupDir: root.storagePicker.memoryCardPath
            unitListModel: root.unitListModel

            topSmallText: state == "error"
                        //% "Choose 'Continue without backup' to update the OS without backing up your data, or 'Cancel' to cancel the OS update. We recommend backing up your data before updating the OS."
                      ? qsTrId("settings_sailfishos-la-backup_failed_detailed_description")
                      : ""
            button1Text: {
                if (state == "error") {
                    //% "Continue without backup"
                    return qsTrId("settings_sailfishos-la-continue_without_backup")
                } else if (state == "success") {
                    return defaultOKText
                }
                return ""
            }
            button2Text: (canCancel || state == "error") ? defaultCancelText : ""

            onButton1Clicked: {
                root.continueOSUpdate()
                pageStack.pop(pageStack.previousPage(root))
            }

            onButton2Clicked: {
                if (canCancel) {
                    progressPage.backupRestore.cancel()
                }
                pageStack.pop(pageStack.previousPage(root))
            }
        }
    }
}
