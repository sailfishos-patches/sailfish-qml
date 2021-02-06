/*
 * Copyright (c) 2012 - 2019 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.2
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0
import Sailfish.Silica.Background 1.0
import "../pages/callhistory"
import "../common/CallHistory.js" as CallHistory

Page {
    id: callingView

    signal completeAnimation()
    signal setAudioRecording(bool recording)

    property Item _incomingCallView
    property Item _inCallView
    property Component _inCallViewComponent
    property alias _callerItem: callerItem

    property string callingState: main.state
    property int callHistoryAnimationDuration: 600
    property var heldCall: telephony.heldCall
    onHeldCallChanged: {
        if (heldCall && telephony.previousPrimaryCall === heldCall && telephony.effectiveCallCount > 1) {
            heldCallAnimation.start()
            newCallAnimation.start()
        }
    }

    property var endingCall: telephony.endingCall
    onEndingCallChanged: {
        if (endingCall && telephony.effectiveCallCount > 1) {
            heldCallAnimation.stop()
            endedCallAnimation.start()
            newCallAnimation.start()
        }
    }

    readonly property color answerHighlightColor: (callingView.palette.colorScheme === Theme.LightOnDark) ? "#AAFF80" : "#226600"
    readonly property color rejectHighlightColor: (callingView.palette.colorScheme === Theme.LightOnDark) ? "#FF3030" : "#660003"

    Component.onCompleted: updateCallingView()
    onCallingStateChanged: updateCallingView()

    function incomingCallView() {
        if (!_incomingCallView) {
            var incomingCallViewComponent = Qt.createComponent("IncomingCallView.qml")

            if (incomingCallViewComponent.status === Component.Ready) {
                _incomingCallView = incomingCallViewComponent.createObject(callingView)
            } else {
                console.log(incomingCallViewComponent.errorString())
            }
            if (!_inCallView) {
                // We're going to need this soon. Get it pre-compiled.
                _inCallViewComponent = Qt.createComponent("InCallView.qml", Component.Asynchronous)
            }
        }
        return _incomingCallView
    }

    function inCallView() {
        if (!_inCallView) {
            if (!_inCallViewComponent || _inCallViewComponent.status != Component.Ready) {
                // It's possible (but unlikely) that we're still compiling this async.
                // There's no way to force completion, so we just create a new one.
                _inCallViewComponent = Qt.createComponent("InCallView.qml")
            }

            if (_inCallViewComponent.status === Component.Ready) {
                _inCallView = _inCallViewComponent.createObject(callingView)
                _inCallView.completeAnimation.connect(callingView.completeAnimation)
                _inCallView.setAudioRecording.connect(callingView.setAudioRecording)
            } else {
                console.log(_inCallViewComponent.errorString())
            }
        }
        return _inCallView
    }

    function updateCallingView() {
        if (main.state === "incoming" || main.state === "silenced") {
            incomingCallView()
            callDialogApplicationWindow.pageStack.pop(callingView)
        } else if (main.state !== "null") {
            inCallView()
        }
    }

    opacity: 0.0
    enabled: main.displayCallView

    CallHistoryItem {
        id: secondCallerItem
        y: Theme.paddingLarge
        enabled: false
        dateColumnVisible: false
        parent: _inCallView ? _inCallView.contentItem : callingView
        person: null
        remoteUid: undefined
        opacity: 0.0
        width: parent.width
        rightMargin: secondCallStateLabel.width + Theme.paddingMedium + Theme.horizontalPageMargin

        Label {
            id: secondCallStateLabel
            anchors {
                right: parent.right
                rightMargin: Theme.horizontalPageMargin
                verticalCenter: parent.verticalCenter
            }
            text: heldCallAnimation.running
                    //% "Holding"
                  ? qsTrId("voicecall-la-call_holding")
                    //% "Ending call"
                  : qsTrId("voicecall-la-call_ending")
        }

        SequentialAnimation {
            id: heldCallAnimation
            ScriptAction {
                script: {
                    secondCallerItem.person = telephony.callerDetails[heldCall.handlerId].person
                    secondCallerItem.remoteUid = telephony.callerDetails[heldCall.handlerId].remoteUid
                }
            }
            ParallelAnimation {
                FadeAnimator {
                    target: secondCallerItem
                    duration: callHistoryAnimationDuration
                    from: 1.0
                    to: 0.0
                }
                YAnimator {
                    target: secondCallerItem
                    from: Theme.paddingLarge
                    to: -Theme.itemSizeSmall
                    duration: callHistoryAnimationDuration
                    easing.type: Easing.InOutQuad
                }
            }
        }

        SequentialAnimation {
            id: endedCallAnimation
            ScriptAction {
                script: {
                    secondCallerItem.person = telephony.callerDetails[endingCall.handlerId].person
                    secondCallerItem.remoteUid = telephony.callerDetails[endingCall.handlerId].remoteUid
                }
            }
            ParallelAnimation {
                FadeAnimator {
                    target: secondCallerItem
                    duration: callHistoryAnimationDuration
                    from: 1.0
                    to: 0.0
                }
                YAnimator {
                    target: secondCallerItem
                    from: Theme.paddingLarge
                    to: Theme.paddingLarge + Theme.itemSizeSmall
                    duration: callHistoryAnimationDuration
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }
    Rectangle {
        anchors.fill: telephony.isEmergency ? parent : null
        opacity: telephony.isEmergency ? 1.0 : 0.0
        color: "#4c0000"
        Behavior on opacity { FadeAnimator {} }
    }
    CallHistoryItem {
        id: callerItem

        y: Theme.paddingLarge
        enabled: false
        parent: callingAnimation.running ? callingView
                                         : (telephony.incomingCall || telephony.silencedCall ? incomingCallView().contentItem : inCallView().contentItem)
        palette {
            primaryColor: (telephony.incomingCall || telephony.silencedCall || newCallAnimation.running) ? "#80ff91" : undefined
            secondaryColor: (telephony.incomingCall || telephony.silencedCall || newCallAnimation.running) ? "#8080ff91" : undefined
        }
        dateColumnVisible: main.state === 'active'
        time: telephony.primaryCallerDetails.startedAt
        person: main.state === "silenced" ? (telephony.silencedCallerDetails && telephony.silencedCallerDetails.person) : (telephony.primaryCallerDetails && telephony.primaryCallerDetails.person)
        remoteUid: main.state === "silenced" ? (telephony.silencedCallerDetails && telephony.silencedCallerDetails.remoteUid) : (telephony.primaryCallerDetails && telephony.primaryCallerDetails.remoteUid)
        visible: !telephony.incomingCall && !telephony.silencedCall || telephony.primaryCall || main.state === "null"
                 || main.state === "disconnected"
    }

    ParallelAnimation {
        id: newCallAnimation
        YAnimator {
            target: callerItem
            from: Theme.paddingLarge + Theme.itemSizeSmall
            to: Theme.paddingLarge
            duration: 300
            easing.type: Easing.InOutQuad
        }
        FadeAnimator {
            target: callerItem
            duration: callHistoryAnimationDuration
            from: 0.0
            to: 1.0
        }
    }
    SequentialAnimation {
        id: callingAnimation
        running: main.displayCallView
        ScriptAction {
            script: {
                callerItem.y = Math.round(callingView.height / 7)
                callerItem.opacity = 0.0
            }
        }
        FadeAnimator {
            target: callingView
            duration: 400
            to: 1.0
        }
        ParallelAnimation {
            FadeAnimator {
                target: callerItem
                duration: callHistoryAnimationDuration
                to: 1.0
            }
            YAnimator {
                target: callerItem
                from: Math.round(callingView.height / 7)
                to: Theme.paddingLarge
                easing.type: Easing.InOutQuad
                duration: main.state !== "dialing" ? 1 : callHistoryAnimationDuration
            }
        }
        ScriptAction {
            script: {
                main.resetMainPage()
                pageStack.pop(null, PageStackAction.Immediate)
            }
        }
    }
    Loader {
        id: conferenceMembers
        active: !!telephony.conferenceCall
        anchors {
            verticalCenter: parent.verticalCenter
            verticalCenterOffset: height/2 + Theme.paddingMedium + Theme.paddingSmall
        }
        x: parent.leftMargin
        width: callingView.width - x - Theme.horizontalPageMargin
        parent: telephony.conferenceCall === telephony.primaryCall ? callerItem : secondCallerItem
        sourceComponent: Label {
            color: palette.secondaryColor
            font.pixelSize: Theme.fontSizeSmall
            truncationMode: TruncationMode.Fade
            function updateText() {
                var newText = ""
                for (var i = 0; i < childCalls.count; ++i) {
                    var obj = childCalls.objectAt(i)
                    if (newText.length !== 0)
                        newText += ", "
                    newText += !obj.person || (obj.person.primaryName.length === 0 && obj.person.secondaryName.length === 0)
                                ? CallHistory.formatNumber(obj.remoteUid)
                                : obj.person.primaryName
                }
                text = newText
            }
            Instantiator {
                id: childCalls
                model: telephony.conferenceCall ? telephony.conferenceCall.childCalls : null
                delegate: QtObject {
                    property string remoteUid: lineId
                    property var person: telephony.callerDetails[handlerId].person
                    onPersonChanged: updateText()
                }
                onObjectAdded: updateText()
                onObjectRemoved: updateText()
            }
        }
    }
}
