import QtQuick 2.0
import Sailfish.Silica 1.0
import "../../common/CallHistory.js" as CallHistory

Row {
    property alias secondaryLabel: secondaryLabel
    spacing: Theme.paddingSmall
    width: parent ? parent.width : Screen.width
    opacity: privateNumber ? Theme.opacityLow : 1.0
    Label {
        id: firstNameText
        text: people.populated || remoteUid !== undefined
              ? (!person || (person.primaryName.length === 0 && person.secondaryName.length === 0)
                 ? CallHistory.formatNumber(remoteUid)
                 : person.primaryName)
              : ""
        truncationMode: TruncationMode.Fade
        width: Math.min(implicitWidth, parent.width)
    }
    Label {
        id: secondaryLabel
        text: people.populated && person ? person.secondaryName : ""
        color: highlighted ? palette.secondaryHighlightColor : palette.secondaryColor
        truncationMode: TruncationMode.Fade
        width: Math.min(implicitWidth, parent.width - x)
        visible: width > 0
    }
}
