import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.settings.sailfishos 1.0

Column {

    Label {
        color: Theme.highlightColor
        font.pixelSize: Theme.fontSizeMedium
        width: parent.width
        height: implicitHeight + 2 * Theme.paddingLarge
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.Wrap
        textFormat: Text.StyledText

        //: Text shown when a new OS update can be downloaded after filesystem
        //: optimizing, which could take a long timr during which you may
        //: continue to use your device, but may notice some slowdowns.
        //% "A new OS update is around the corner.<br><br>To be able to download the OS update, we need to maintenance the filesystem. This requires approx. 1.5 GB of free space.<br><br>You will be able to use your device, but you might notice some slowdowns. It may take up to an hour to complete."
        text: qsTrId("settings_sailfishos-la-fs_optimizing_for_os_update")
    }

    Button {
        visible: !btrfsBalancer.balancing
        anchors.horizontalCenter: parent.horizontalCenter
        //: Text for filesystem optimizing button
        //% "Start optimizing"
        text: qsTrId("settings_sailfishos-bt-start_fs_optimizing")

        onClicked: {
            btrfsBalancer.start()
        }
    }

    ProgressBar {
        visible: btrfsBalancer.balancing
        width: parent.width - 2 * Theme.paddingLarge
        anchors.horizontalCenter: parent.horizontalCenter
        minimumValue: 0
        maximumValue: 100
        value: btrfsBalancer.progress
        indeterminate: value === 0
        //: Progress label shown while optimizing the filesystem
        //% "Optimizing in progress"
        label: qsTrId("settings_sailfishos-la-fs_optimizing_in_progress")
    }
}
