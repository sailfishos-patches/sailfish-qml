import QtQuick 2.0
import Sailfish.Silica 1.0

MouseArea {
    id: hintLoader

    property Item hint
    property string source
    signal started

    function start() {
        if (!hint) {
            var component = Qt.createComponent(Qt.resolvedUrl(source))
            if (component.status == Component.Ready) {
                hint = component.createObject(incomingCallView.contentItem)
            } else {
                console.warn(source + " instantiation failed " + component.errorString())
            }
        }
        started()
    }
    function stop() {
        if (hint) hint.running = false
    }

    onClicked: start()
    onReleased: pulleyAnimationHint.resume()
    onPressed: {
        if (pulleyAnimationHint.running) {
            pulleyAnimationHint.pause()
        }
    }
    anchors { fill: parent; margins: -Theme.paddingLarge }
}
