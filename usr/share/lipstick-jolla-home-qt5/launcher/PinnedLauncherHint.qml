import QtQuick 2.6
import Sailfish.Silica 1.0

InteractionHintLabel {
    id: root

    property int launcherAbsoluteExposure
    signal closed

    function show() {
        enabled = (root.parent.height - root.launcherAbsoluteExposure) > root.height
    }

    function hide() {
        enabled = false
    }

    function close() {
        hide()
        closed()
    }

    Component.onCompleted: show()
    onVisibleChanged: if (!visible) hide()

    //% "Swipe up and hold to pin the App Grid. Pinning allows you to access the top-most apps more easily."
    text: qsTrId("lipstick-jolla-home-la-pinned_launcher_hint")

    enabled: false
    topMargin: 3*Theme.paddingLarge
    bottomMargin: button.height + button.anchors.bottomMargin + Theme.paddingLarge
    y: parent.height - height - launcherAbsoluteExposure

    opacity: enabled ? 1.0 : 0.0
    Behavior on opacity { FadeAnimation { duration: 400 } }

    Button {
        id: button
        //% "Got it"
        text: qsTrId("lipstick-jolla-home-la-got_it")
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 2*Theme.paddingLarge
        }
        onClicked: root.close()
    }
}

