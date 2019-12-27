import QtQuick 2.2
import Sailfish.Silica 1.0
import Sailfish.Telephony 1.0
import QtQuick.Window 2.1
import Sailfish.Lipstick 1.0

SystemDialog {
    id: simSelector
    property string number
    contentHeight: picker.height

    onVisibilityChanged: {
        if (visibility == Window.Hidden) {
            destroy()
        }
    }

    SimPicker {
        id: picker
        onSimSelected: {
            simSelector.close()
            telephony.dialNumberOrService(simSelector.number, modemPath)
        }
    }
}
