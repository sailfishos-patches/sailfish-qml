import QtQuick 2.2
import Sailfish.Silica 1.0

Transition {
    property Item page
    property QtObject applicationWindow
    to: 'Portrait,Landscape,PortraitInverted,LandscapeInverted'
    from: 'Portrait,Landscape,PortraitInverted,LandscapeInverted'
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
            target: page
            properties: 'width,height,rotation,orientation'
        }
        ScriptAction {
            script: {
                // Restores the Bindings to width, height and rotation
                _defaultTransition = false
                _defaultTransition = true
            }
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
