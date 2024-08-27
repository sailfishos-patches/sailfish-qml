import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Ngf 1.0
import Nemo.Alarms 1.0
import Nemo.Configuration 1.0
import com.jolla.alarmui 1.0

SilicaFlickable {
    id: alarmDialogBase

    anchors.fill: parent
    contentHeight: parent.height
    flickableDirection: Flickable.VerticalFlick

    property QtObject alarm: dummy

    property int status: -1
    property alias topIconSource: topIcon.source
    default property alias _content: content.children
    property alias pushUpAnimationHint: pulleyAnimationHint.pushUpHint
    property alias spacing: content.spacing
    property alias animating: fadeOut.running

    signal dialogHidden(int status)
    signal timeout()

    function show(alarm) {
        if (fadeOut.running) {
            console.log("jolla-alarm-ui: Warning: fadeOut running and show called")
            fadeOut.stop()
        }
        alarmDialogBase.alarm = alarm
        status = AlarmDialogStatus.Open
        opacity = 1.0
        if (alarm.type !== Alarm.Calendar || !doNotDisturb.value) {
            feedback.play()
        }
        timeoutTimer.start()
    }

    function closeDialog(status) {
        alarmDialogBase.status = status
        feedback.stop()
        timeoutTimer.stop()
        fadeOut.start()
    }

    function hide() {
        feedback.stop()
        timeoutTimer.stop()
        status = AlarmDialogStatus.Invalid
        if (fadeOut.running || opacity == 0) {
            return // Dialog is fading out or is already hidden
        }
        fadeOut.start()
    }

    function hideImmediatedly() {
        opacity = 0
        feedback.stop()
        alarmDialogBase.alarm = dummy
        timeoutTimer.stop()
        if (fadeOut.running) {
            console.log("Warning: fadeOut running and hideImmediatedly() called")
            fadeOut.stop()
        }
    }

    QtObject {
        id: dummy

        property string title
        property date startDate
        property date endDate
        property bool allDay
        property int hour
        property int minute
        property int second
        property string notebookUid
        property string calendarEventUid
        property string calendarEventRecurrenceId
        property int type
    }

    PulleyAnimationHint {
        id: pulleyAnimationHint

        anchors.fill: parent
        pushUpHint: true
        pullDownDistance: Theme.itemSizeLarge + (pushUpHint ? Theme.itemSizeExtraSmall : 0)
    }

    NonGraphicalFeedback {
        id: feedback

        event: alarm.type === Alarm.Calendar ? "calendar" : "clock"
    }

    ConfigurationValue {
        id: doNotDisturb

        defaultValue: false
        key: "/lipstick/do_not_disturb"
    }

    Image {
        id: topIcon

        anchors.horizontalCenter: parent.horizontalCenter
        y: Theme.paddingLarge
    }

    Column {
        id: content

        anchors {
            left: parent.left
            right: parent.right
            bottom: dismissIcon.top
            margins: Theme.horizontalPageMargin
            bottomMargin: 4*Theme.paddingLarge
        }
        move: Transition { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad; property: "y" } }
    }

    Image {
        id: dismissIcon

        anchors {
            bottom: parent.bottom
            bottomMargin: Theme.paddingLarge
            horizontalCenter: parent.horizontalCenter
        }
        source: "image://theme/icon-l-dismiss?" + Theme.highlightColor
    }

    PushUpMenu {
        quickSelect: true
        topMargin: Theme.itemSizeExtraSmall
        MenuItem {
            //% "Dismiss"
            text: qsTrId("alarm-ui-me-alarm_dialog_dismiss")
            onClicked: closeDialog(AlarmDialogStatus.Dismissed)
        }
    }

    Timer {
        id: timeoutTimer

        interval: 60000
        onTriggered: timeout()
    }

    // Use a Timer to let fade out animation (see id fadeOut) complete before closing,
    // dismissing, or snoozing an alarm.
    Timer {
        id: dialogHiddenDelayer

        interval: 1
        onTriggered: dialogHidden(status)
    }

    SequentialAnimation {
        id: fadeOut

        PropertyAnimation {
            target: alarmDialogBase
            property: "opacity"
            to: 0
            duration: 1000
        }
        ScriptAction { script: { alarmDialogBase.alarm = dummy } }
        ScriptAction { script: { dialogHiddenDelayer.start() } }
    }
}
