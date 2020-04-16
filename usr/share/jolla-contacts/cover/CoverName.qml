import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    anchors.fill: parent

    CoverNameLabel {
        id: firstNameLabel

        text: coverContact.firstText
        center: coverContact.center
        anchors {
            bottom: parent.verticalCenter
            left: parent.left
            right: parent.right
            bottomMargin: Theme.paddingMedium
            leftMargin: Theme.paddingMedium
            rightMargin: Theme.paddingMedium
        }
    }

    CoverNameLabel {
        text: coverContact.secondText
        center: coverContact.center
        opacity: Theme.opacityHigh
        anchors {
            top: firstNameLabel.bottom
            left: parent.left
            right: parent.right
            leftMargin: Theme.paddingMedium
            rightMargin: Theme.paddingMedium
        }
    }
}
