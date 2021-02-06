
import QtQuick 2.0
import Sailfish.Silica 1.0

CoverBackground {

    Rectangle {
        anchors.fill: parent
        color: "#00000000"
    }

    Label {
        id: title

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: Theme.paddingSmall
        }

        font {
            pixelSize: Theme.fontSizeSmall
        }

        color: Theme.primaryColor
        text: appWindow.windowTitle

    }

    Label {
        anchors {
            top: (title.text != '') ? title.bottom : parent.top
            left: parent.left
            bottom: parent.bottom
            margins: Theme.paddingSmall
        }

        font {
            family: util.settingsValue("ui/fontFamily")
            pixelSize: Theme.fontSizeTiny / 2
        }

        color: Theme.primaryColor

        // Align bottom and clip to ensure that the cover displays
        // the last lines in the display buffer on the cover (i.e. the
        // latest commands).
        clip: true;
        verticalAlignment : Text.AlignBottom

        text: {
            var res = ''
            for (var i=0; i<appWindow.lines.length; i++) {
                res = res + appWindow.lines[i] + '\n'
            }
            return res.trim()
        }
    }
}
