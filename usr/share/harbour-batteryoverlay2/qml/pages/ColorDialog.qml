import QtQuick 2.1
import Sailfish.Silica 1.0
import "../components"

Dialog
{
    id: dialog
    canAccept: true

    property string color
    property string selectedColor

    SilicaFlickable
    {
        id: flick

        anchors.fill: parent
        contentHeight: dialogHeader.height + col.height
        width: parent.width

        VerticalScrollDecorator { flickable: flick }

        DialogHeader
        {
            id: dialogHeader
            acceptText: qsTr("Select color")
            Timer
            {
                interval: 2500
                running: true
                onTriggered: dialogHeader.acceptText = dialogHeader.defaultAcceptText
            }
        }

        Column
        {
            id: col
            width: parent.width - Theme.paddingLarge
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: dialogHeader.bottom

            ColorSelector
            {
                isColorWheel: true
                previewColor: dialog.color
                onSelectedColorChanged: dialog.selectedColor = selectedColor
            }
        }
    }
}
