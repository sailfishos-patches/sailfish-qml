/*
* Copyright (c) 2020 Open Mobile Platform LLC.
*
* License: Proprietary
*/

import QtQuick 2.6
import Sailfish.Silica 1.0

Row {
    id: root

    property string firstText
    property string secondText
    property bool unnamed
    property bool useAlternateColors: true

    property alias firstNameLabel: firstNameLabel
    property alias lastNameLabel: lastNameLabel

    readonly property real _remainingWidth: Math.max(width - firstNameLabel.width - spacing, 0)

    width: parent.width
    spacing: Format._needsSpaceBetweenNames(firstText, secondText) ? Theme.paddingSmall : 0

    Label {
        id: firstNameLabel
        text: root.unnamed
                //: Default text shown instead of a contact name, if the contact name is not known
                //% "Unnamed"
              ? qsTrId("components_contacts-la-unnamed_contact")
              : firstText
        color: highlighted ? Theme.highlightColor: (root.unnamed ? Theme.secondaryColor : Theme.primaryColor)
        width: Math.min(implicitWidth, root.width)
        truncationMode: width == root.width ? TruncationMode.Fade : TruncationMode.None
        textFormat: Text.AutoText
    }

    Label {
        id: lastNameLabel

        text: secondText
        color: useAlternateColors
               ? (highlighted ? Theme.secondaryHighlightColor: Theme.secondaryColor)
               : (highlighted ? Theme.highlightColor: Theme.primaryColor)
        width: Math.min(implicitWidth, _remainingWidth)
        truncationMode: width > 0 && width == _remainingWidth ? TruncationMode.Fade : TruncationMode.None
        textFormat: Text.AutoText
        visible: width > 0
    }
}
