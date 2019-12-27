import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.settings.system 1.0
import org.nemomobile.devicelock 1.0

Page {
    id: page

    property FingerprintSensor fingerprintSettings
    property variant fingerprintId
    property string fingerprintName
    property date acquisitionDate

    signal removeFinger(variant fingerId)

    onStatusChanged: {
        if (status == PageStatus.Deactivating) {
            if (nameEdit.text != ""
                        && page.fingerprintName != nameEdit.text
                        && fingerprintSettings.fingers.rename(fingerprintId, nameEdit.text)) {
                fingerprintName = nameEdit.text
            } else {
                nameEdit.text = fingerprintName
            }
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height

        PullDownMenu {
            MenuItem {
                //% "Delete"
                text: qsTrId("settings_devicelock-me-delete")
                onClicked: page.removeFinger(page.fingerprintId)
            }
        }

        Column {
            id: content

            width: page.width

            PageHeader {
                title: page.fingerprintName
            }

            TextField {
                id: nameEdit

                width: content.width
                text: page.fingerprintName

                //: The fingerprint was captured on the date %1.
                //% "Set up on %1"
                label: qsTrId("settings_devicelock-la-acquisition_date")
                            .arg(Format.formatDate(page.acquisitionDate, Formatter.DateMedium))
            }
        }
    }
}
