import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.commhistory 1.0
import org.nemomobile.contacts 1.0
import Sailfish.Contacts 1.0
import com.jolla.voicecall 1.0
import "../../common"

ListItem {
    id: historyItem

    property bool showDetails
    property date time: main.today
    property var call
    property var remoteUid
    property string connection
    property bool dateColumnVisible: true
    property var person
    property bool privateNumber: remoteUid === ""
    property bool showNumberDetail
    property string numberDetail: {
        if (showNumberDetail) {
            var label = main.getNumberDetail(person, remoteUid)
            return label.length > 0 ? label : defaultNumberDetail
        }
        return ""
    }

    property string subscriberIdentity
    readonly property int leftMargin: Math.max(Theme.horizontalPageMargin, callDirectionIcon.width + 2*Theme.paddingMedium)
    property int rightMargin: Theme.horizontalPageMargin
    property alias reminder: reminder

    //% "Phone"
    property string defaultNumberDetail: qsTrId("voicecall-la-detail_phone")

    width: parent ? parent.width : 0
    contentHeight: Math.max(Theme.itemSizeSmall, content.height + (showDetails ? 3 : 2) * Theme.paddingMedium)

    Reminder {
        id: reminder

        phoneNumber: historyItem.remoteUid || ""
        _reminders: Reminders
    }

    Loader {
        id: content

        width: parent.width - rightMargin
        anchors.verticalCenter: parent.verticalCenter
        source: showDetails ? "DetailedHistoryItem.qml" : "BasicHistoryItem.qml"
    }
}
