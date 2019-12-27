import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Ambience 1.0
import com.jolla.gallery.ambience 1.0

Page {
    id: page

    AmbienceList {
        anchors.fill: parent

        model: AmbienceModel {}

        header: PageHeader {
            //% "Ambiences"
            title: qsTrId("jolla-gallery-ambience-he-ambiences")
        }

        onAmbienceSelected: pageStack.animatorPush("com.jolla.gallery.ambience.AmbienceSettingsPage", { "contentId": ambience.contentId })
    }
}
