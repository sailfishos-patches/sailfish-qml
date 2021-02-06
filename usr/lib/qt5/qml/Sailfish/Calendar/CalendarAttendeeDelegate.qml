import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.calendar 1.0

SilicaControl {
    id: root

    property alias name: nameLabel.text
    property alias secondaryText: extraText.text
    property int participationStatus

    property alias nameColor: nameLabel.color

    height: secondaryText !== "" ? Theme.itemSizeMedium : Theme.itemSizeExtraSmall

    Label {
        id: nameLabel

        y: (root.height - height - (secondaryText !== "" ? extraText.height : 0)) / 2

        width: statusIcon.status === Image.Ready
                ? statusIcon.x - Theme.paddingMedium
                : root.width

        truncationMode: TruncationMode.Fade
    }

    Label {
        id: extraText

        y: nameLabel.y + nameLabel.height

        font.pixelSize: Theme.fontSizeSmallBase
        color: palette.secondaryColor
    }

    Icon {
        id: statusIcon

        x: root.width - width
        y: nameLabel.y + (nameLabel.height - height) / 2

        color: palette.highlightColor

        source: {
            switch (root.participationStatus) {
            case Person.AcceptedParticipation:
                return "image://theme/icon-s-accept"
            case Person.DeclinedParticipation:
                return "image://theme/icon-s-decline"
            case Person.TentativeParticipation:
                return "image://theme/icon-s-maybe"
            }
            return ""
        }
    }
}
