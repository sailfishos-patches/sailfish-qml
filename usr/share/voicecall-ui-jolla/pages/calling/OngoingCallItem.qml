import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.contacts 1.0
import org.nemomobile.voicecall 1.0
import "../callhistory"

CallHistoryItem {
    id: ongoingCall
    property QtObject caller: telephony.primaryCall ? telephony.primaryCallerDetails : telephony.silencedCallerDetails
    property var callStatus: caller ? caller.callStatus : VoiceCall.STATUS_NULL
    property bool initialized
    onCallerChanged: {
        if (caller) {
            remoteUid = caller.remoteUid
            person = caller.person
        }
    }
    width: parent.width
    rightMargin: stateLabel.width + Theme.paddingMedium + Theme.horizontalPageMargin
    dateColumnVisible: false
    palette {
        primaryColor: "#00CC00"
        secondaryColor: "#00AA00"
    }
    enabled: main.addCallMode || telephony.silencedCall
    onEnabledChanged: {
        // Appear immediately so that we don't see transition when in call view closes
        // but hide with animation in case the call ends while are watching.
        if (enabled) {
            fadeAnimation.stop()
            opacity = 1.0
        } else if (initialized) {
            fadeAnimation.start()
        } else {
            opacity = 0.0
        }
    }
    Component.onCompleted: initialized = true
    FadeAnimation {
        id: fadeAnimation
        target: ongoingCall
        to: 0.0
    }

    onClicked: {
        main.addCallMode = false
        if (callStatus == VoiceCall.STATUS_INCOMING && caller.silenced) {
            main.showCallView()
            main.hangupAnimation.start()
            main.hangupAnimation.pause()
        } else if (telephony.primaryCall) {
            main.showCallView()
        }
    }
    Label {
        id: stateLabel
        anchors {
            right: parent.right
            rightMargin: Theme.horizontalPageMargin
            verticalCenter: parent.verticalCenter
        }
        text: ongoingCall.stateString()
    }

    function stateString() {
        if (callStatus == VoiceCall.STATUS_INCOMING) {
            if (caller.silenced) {
                //: Incoming call in call history, which user has muted
                //% "muted"
                return qsTrId("voicecall-la-history-muted")
            } else {
                //: Incoming call in call history
                //% "incoming"
                return qsTrId("voicecall-la-history-incoming")
            }
        } else if (callStatus == VoiceCall.STATUS_HELD) {
            //: Held call in call history
            //% "on hold"
            return qsTrId("voicecall-la-on-history-hold")
        } else if (callStatus == VoiceCall.STATUS_ACTIVE) {
            //: Active call in call history
            //% "ongoing"
            return qsTrId("voicecall-la-history-ongoing")
        } else if (callStatus == VoiceCall.STATUS_DIALING) {
            //: Dialing call in call history
            //% "calling"
            return qsTrId("voicecall-la-history-dialing")
        }
        return ""
    }
}
