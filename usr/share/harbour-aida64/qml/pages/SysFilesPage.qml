import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.aida64.infopageloader 1.0

Page {
    property int horizPageMargin: {
        if (Theme.horizontalPageMargin) return Theme.horizontalPageMargin
        else return Theme.paddingLarge
    }

    property string sysfile_name

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        InfoPageLoader {
            id: infopageloader
        }

        Column {
            id: column
            x: horizPageMargin
            width: parent.width - 2 * x
            spacing: Theme.paddingLarge

            PageHeader {
                title: sysfile_name
            }

            Label {
                width: parent.width
                text: infopageloader.loadSysFile(sysfile_name)
                color: Theme.primaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
                font.family: "Monospace"
                wrapMode: Text.Wrap
            }
        }

        Loader {
            source: "PullDownMenu.qml"
        }

        VerticalScrollDecorator {}
    }
}
