import QtQuick 2.2
import Sailfish.Silica 1.0

Transition {
    property Item page
    property QtObject applicationWindow
    to: 'Portrait,Landscape,PortraitInverted,LandscapeInverted'
    from: 'Portrait,Landscape,PortraitInverted,LandscapeInverted'

    onRunningChanged: {
        if (!running) {
            applicationWindow.contentItem.opacity = 1
        }
    }

    SequentialAnimation {
        PropertyAction {
            target: page
            property: 'orientationTransitionRunning'
            value: true
        }
        FadeAnimation {
            target: applicationWindow.contentItem
            to: 0
            duration: 250
        }
        PropertyAction {
            properties: 'width,height,rotation,orientation'
        }
        FadeAnimation {
            target: applicationWindow.contentItem
            to: 1
            duration: 250
        }
        PropertyAction {
            target: page
            property: 'orientationTransitionRunning'
            value: false
        }
    }
}
