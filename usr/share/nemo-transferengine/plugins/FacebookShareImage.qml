import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.systemsettings 1.0
import Sailfish.TransferEngine 1.0

ShareFilePreviewDialog {
    id: root

    shareItem.metadataStripped: true

    //: Describes where mobile uploads will go. %1 is an operating system name
    //% "Mobile uploads from %1"
    remoteDirName: qsTrId("webshare-la-uploads-text").arg(aboutSettings.operatingSystemName)

    onAccepted: {
        shareItem.start()
    }

    AboutSettings {
        id: aboutSettings
    }
}
