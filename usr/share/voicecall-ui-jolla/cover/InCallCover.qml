import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.contacts 1.0
import "../common/CallHistory.js" as CallHistory

Item {
    property var callerDetails: telephony.incomingCall ? telephony.incomingCallerDetails
                                                       : (telephony.silencedCall ? telephony.silencedCallerDetails
                                                                                 : telephony.primaryCallerDetails)
    anchors.fill: parent
    visible: telephony.active || main.displayDisconnected

    Image {
        // avatar
        opacity: Theme.opacityHigh
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        source: callerDetails ? callerDetails.avatar : ""
    }
    OpacityRampEffect {
        sourceItem: caller
        offset: 0.5
    }

    Image {
        id: icon
        source: telephony.incomingCall || telephony.silencedCall ? "image://theme/icon-s-incoming-call" : ""
        x: Theme.paddingMedium
        anchors.verticalCenter: caller.verticalCenter
    }

    CoverLabel {
        id: caller

        y: Theme.paddingLarge
        person: callerDetails.person
        remoteUid: callerDetails.remoteUid
        anchors.right: parent.right
        anchors.left: parent.left
        anchors.leftMargin: callDirectionIcon.width + 2*Theme.paddingMedium
    }

    Label {
        id: stateLabel

        text: (main.state === 'incoming' || main.state === 'silenced')
              ? //: Someone is calling us
                //% "Calling"
                qsTrId("voicecall-la-calling_state")
              : main.state === "held" ? qsTrId("voicecall-la-held_state")
                                      : CallHistory.durationText(telephony.callDuration)
        anchors {
            left: caller.left
            right: parent.right
            rightMargin: Theme.paddingLarge
            top: caller.bottom
        }
        truncationMode: TruncationMode.Fade
        color: Theme.highlightColor
        font.pixelSize: Theme.fontSizeSmall
    }
    Label {
        text: telephony.error
        color: Theme.highlightColor
        visible: main.state === 'disconnected' || main.state === 'null'
        font.pixelSize: Theme.fontSizeSmall
        wrapMode: Text.Wrap
        horizontalAlignment: Qt.AlignHCenter
        anchors {
            top: stateLabel.bottom
            left: parent.left
            leftMargin: Theme.paddingMedium
            right: parent.right
            rightMargin: Theme.paddingMedium
        }
    }
    CoverActionList {
        enabled: telephony.active && main.state !== 'incoming' && main.state !== 'held' && main.state !== 'silenced' && !telephony.isMicrophoneMuted
        CoverAction {
            iconSource: "image://theme/icon-cover-hangup"
            onTriggered: {
                telephony.hangupCall(telephony.primaryCall)
            }
        }
    }
    Label {
        //% "Muted"
        text: qsTrId("voicecall-la-muted")
        color: Theme.highlightColor
        visible: telephony.isMicrophoneMuted
        anchors {
            bottomMargin: 110*scaleRatio
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }
    }
    CoverActionList {
        enabled: main.state === 'held' && !telephony.isMicrophoneMuted
        CoverAction {
            iconSource: "image://theme/icon-cover-play"
            onTriggered: telephony.primaryCall.hold(false)
        }
    }
    CoverActionList {
        enabled: main.state === 'incoming' || main.state === 'silenced'
        CoverAction {
            iconSource: "image://theme/icon-cover-answer"
            onTriggered: {
                if (main.state === 'silenced') {
                    telephony.silencedCallerDetails.silenced = false
                    // telephony.silencedCall changes to telephony.incomingCall
                }
                telephony.incomingCall.answer()
                main.activate()
            }
        }
    }
    CoverActionList {
        enabled: telephony.isMicrophoneMuted
        CoverAction {
            iconSource: "image://theme/icon-cover-unmute"
            onTriggered: telephony.isMicrophoneMuted = false
        }
    }
}
