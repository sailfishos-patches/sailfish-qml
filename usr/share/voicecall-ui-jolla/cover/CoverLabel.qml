import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.contacts 1.0
import com.jolla.voicecall 1.0
import "../common/CallHistory.js" as CallHistory
import "../common"

Row {
    property Person person
    property var remoteUid
    property bool privateNumber: remoteUid === ""

    opacity: privateNumber ? Theme.opacityLow : 1.0
    spacing: Theme.paddingSmall

    Label {
        id: firstNameText
        text: (remoteUid !== undefined && remoteUid !== null)
              ? (!person || (person.primaryName.length === 0 && person.secondaryName.length === 0)
                 ? CallHistory.formatNumber(remoteUid)
                 : person.primaryName)
              : ""

        color: Theme.primaryColor
        truncationMode: TruncationMode.Fade
        width: Math.min(implicitWidth, parent.width)
    }
    Label {
        text: person ? person.secondaryName : ""
        color: Theme.secondaryColor
        truncationMode: TruncationMode.Fade
        width: Math.min(implicitWidth, parent.width - firstNameText.width)
        visible: width > 0
    }
}
