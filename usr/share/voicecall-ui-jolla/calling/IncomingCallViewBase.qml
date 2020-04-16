import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Telephony 1.0
import "../common/CallHistory.js" as CallHistory

SilicaFlickable {
    id: incomingCallView

    // Just the visual interface, don't put any engine or model specific code here!!

    property bool active
    property string phoneNumber
    property string firstText
    property string secondText
    property bool callWaiting
    property bool forwarded
    property bool silenced
    property bool menuActive: answerMenu.active || rejectMenu.active
    property int callCount
    readonly property bool lightOnDark: answerMenu.palette.colorScheme === Theme.LightOnDark
    readonly property bool showCountry: phoneNumberParser.localizedCountryName.length > 0
                                        && (telephony.registrationStatus === "roaming" || phoneNumberParser.regionCode !== telephony.country)

    signal answered
    signal endActiveAndAnswered
    signal rejected
    signal rejectedWithSms
    signal muted

    function qsTrIdStrings()
    {
        //% "Answer"
        QT_TRID_NOOP("voicecall-me-answer")
        //% "...hold ongoing"
        QT_TRID_NOOP("voicecall-me-hold_ongoing")
    }
    function stopHints() {
        pulleyAnimationHint.stop()
        answerHint.stop()
        rejectHint.stop()
    }

    onActiveChanged: {
        if (active) {
            // make sure menus are closed from the last incoming call
            answerMenu.close(true)
            rejectMenu.close(true)
            pulleyAnimationHint.start()
        } else {
            delayedStopHintsTimer.start()
        }
    }
    onDraggingChanged: {
        if (dragging) {
            stopHints()
        } else if (active) {
            pulleyAnimationHint.start()
        }
    }


    anchors.fill: parent
    contentHeight: height
    flickableDirection: Flickable.VerticalFlick
    enabled: active || menuActive
    opacity: active ? 1.0 : 0.0
    interactive: !silenced

    Behavior on opacity { FadeAnimation { id: fadeAnimation; duration: active ? 200 : 350 } }


    PhoneNumber {
        id: phoneNumberParser
        defaultRegionCode: telephony.country
        rawPhoneNumber: phoneNumber
    }
    FirstTimeUseCounter {
        property bool showHint: active && incomingCallView.active

        limit: 2
        defaultValue: 1000 // only show for new users
        key: "/sailfish/voicecall/incoming_call_hint_count"
        onShowHintChanged: {
            if (showHint) {
                increase()
                delayedAnswerHintTimer.restart()
            }
        }
    }
    Timer {
        id: delayedAnswerHintTimer
        interval: 1000
        onTriggered: answerHint.start()
    }

    Timer {
        id: delayedStopHintsTimer
        interval: fadeAnimation.duration
        onTriggered: stopHints()
    }
    SequentialAnimation {
        id: pulleyAnimationHint

        property real distance: Theme.paddingMedium

        loops: Animation.Infinite
        alwaysRunToEnd: true
        PauseAnimation { duration: 800 }
        NumberAnimation {
            target: content
            property: "y"
            from: 0
            to: -pulleyAnimationHint.distance
            duration: 200
            easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            target: content
            property: "y"
            from: -pulleyAnimationHint.distance
            to: pulleyAnimationHint.distance
            duration: 400
            easing.type: Easing.InOutQuad
        }
        NumberAnimation {
            target: content
            property: "y"
            from: pulleyAnimationHint.distance
            to: 0
            duration: 200
            easing.type: Easing.InOutQuad
        }
    }

    Binding {
        target: main
        when: answerMenu.active
        property: "dimmedRegionColor"
        value: "#003307"
    }
    PullDownMenu {
        id: answerMenu

        palette.highlightColor: lightOnDark ? "#AAFF80" : "#226600"

        quickSelect: true
        bottomMargin: callWaiting ? Theme.itemSizeExtraSmall - Theme.paddingLarge : Theme.itemSizeExtraSmall

        MenuItem {
            visible: callCount <= 2
            text: callWaiting ? qsTrId("voicecall-me-hold_ongoing") : qsTrId("voicecall-me-answer")
            onClicked: incomingCallView.answered()
        }
        MenuItem {
            visible: callWaiting
            //% "...end ongoing"
            text: qsTrId("voicecall-me-end_ongoing")
            onClicked: incomingCallView.endActiveAndAnswered()
        }
        MenuLabel {
            visible: callWaiting
            height: Theme.itemSizeExtraSmall
            //% "Answer and..."
            text: qsTrId("voicecall-la-answer_and")
        }
    }

    Item {
        visible: callWaiting && active
        y: Theme.paddingLarge
        height: _callerItem.height
        anchors.right: parent.right
        anchors.rightMargin: Theme.paddingLarge
        Label {
            id: ongoingLabel
            //% "Call ongoing"
            text: qsTrId("voicecall-la-call_ongoing")
            color: answerMenu.highlightColor
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
        }

        states: State {
            when: ongoingLabel.visible
            PropertyChanges { target: _callerItem; width: incomingCallView.width - ongoingLabel.width }
        }
    }

    Item {
        id: content

        width: incomingCallView.width
        height: incomingCallView.height

        Column {
            id: labelColumn

            anchors {
                left: parent.left
                right: parent.right
                bottom: rejectLabel.top
                bottomMargin: Theme.itemSizeSmall
                leftMargin: Theme.horizontalPageMargin
                rightMargin: Theme.horizontalPageMargin
            }
            Image {
                visible: opacity > 0.0
                opacity: forwarded ? 1.0 : 0.0
                Behavior on opacity { FadeAnimation {} }
                anchors.horizontalCenter: parent.horizontalCenter
                source: "image://theme/icon-l-redirect"
            }
            Label {
                width: parent.width
                visible: text.length > 0
                horizontalAlignment: Text.AlignHCenter
                text: firstText.length > 0 || secondText.length > 0 ? firstText : CallHistory.formatNumber(phoneNumber)
                font { family: Theme.fontFamilyHeading; pixelSize: Theme.fontSizeHuge }
                elide: Text.ElideRight
                maximumLineCount: 2
                wrapMode: Text.Wrap
            }
            Label {
                text: secondText
                width: parent.width
                visible: text.length > 0
                horizontalAlignment: Text.AlignHCenter
                font { family: Theme.fontFamilyHeading; pixelSize: Theme.fontSizeHuge }
                elide: Text.ElideRight
                maximumLineCount: 2
                wrapMode: Text.Wrap
            }
            Label {
                //: i.e. "John calling" or "0123456 calling"
                //% "calling"
                text: qsTrId("voicecall-la-calling")
                width: parent.width
                truncationMode: TruncationMode.Fade
                horizontalAlignment: Text.AlignHCenter
                font { family: Theme.fontFamilyHeading; pixelSize: Theme.fontSizeLarge }
            }
            Label {
                width: parent.width
                height: implicitHeight + Theme.paddingLarge
                truncationMode: TruncationMode.Fade
                horizontalAlignment: implicitWidth > width ? Text.AlignLeft : Text.AlignHCenter
                verticalAlignment: Text.AlignBottom
                font.pixelSize: Theme.fontSizeSmall
                visible: text.length > 0
                text: telephony.simNameForCall(telephony.incomingCall)
            }
            Label {
                width: parent.width
                height: implicitHeight + Theme.paddingLarge
                truncationMode: TruncationMode.Fade
                horizontalAlignment: implicitWidth > width ? Text.AlignLeft : Text.AlignHCenter
                verticalAlignment: Text.AlignBottom
                font.pixelSize: Theme.fontSizeSmall
                color: palette.secondaryColor
                visible: showCountry
                text: phoneNumberParser.localizedCountryName
            }
        }

        HighlightImage {
            id: answerIcon

            visible: !callWaiting
            y: Theme.paddingLarge
            anchors.horizontalCenter: parent.horizontalCenter
            source: "image://theme/icon-l-answer"
            color: "#00CC00"
            CallHintLoader {
                id: answerHint
                source: "AnswerCallHint.qml"
                onStarted: rejectHint.stop()
            }
        }

        Label {
            anchors {
                left: parent.left
                leftMargin: Theme.horizontalPageMargin
                right: parent.right
                rightMargin: Theme.horizontalPageMargin
                top: answerIcon.bottom
                topMargin: Theme.paddingSmall
            }
            //: Action to accept the incoming call
            //% "Pull down to answer"
            text: qsTrId("voicecall-me-pull_down_to_answer")
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            visible: !callWaiting
            color: answerMenu.highlightColor
            font.pixelSize: Theme.fontSizeExtraSmall
        }

        Label {
            id: rejectLabel
            anchors {
                left: parent.left
                leftMargin: Theme.horizontalPageMargin
                right: parent.right
                rightMargin: Theme.horizontalPageMargin
                bottom: rejectIcon.top
            }
            //: Action to silence the incoming call
            //% "Pull up to silence"
            text: qsTrId("voicecall-me-pull_up_to_silence")
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            color: rejectMenu.highlightColor
            font.pixelSize: Theme.fontSizeExtraSmall
        }

        HighlightImage {
            id: rejectIcon

            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: Theme.paddingMedium
            }
            source: "image://theme/icon-l-reject"
            color: "#CC0000"
            CallHintLoader {
                id: rejectHint
                source: "RejectCallHint.qml"
                onStarted: answerHint.stop()
            }
        }
    }
    Binding {
        target: main
        when: rejectMenu.active
        property: "dimmedRegionColor"
        value: "#330000"
    }
    PushUpMenu {
        id: rejectMenu

        palette.highlightColor: lightOnDark ? "#FF8080" : "#660003"

        quickSelect: true
        topMargin: Theme.itemSizeExtraSmall

        MenuItem {
            //: Action to silence the incoming call
            //% "Silence"
            text: qsTrId("voicecall-me-ignore")
            onClicked: incomingCallView.muted()
        }
    }
}
