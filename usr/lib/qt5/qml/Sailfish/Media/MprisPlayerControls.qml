import QtQuick 2.0
import Amber.Mpris 1.0

/*!
  \qmltype MprisPlayerControls
  \inqmlmodule Sailfish.Media
*/
Loader {
    id: controlsLoader

    active: mprisController.availableServices.length > 0

    Component.onCompleted: setSource("MprisManagerControls.qml", { "mprisController": mprisController, "parent": Qt.binding(function() { return controlsLoader.parent }) })

    MprisController {
        id: mprisController
    }
}
