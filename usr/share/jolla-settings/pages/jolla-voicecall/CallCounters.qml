import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.DBus 2.0
import Nemo.Time 1.0
import com.jolla.voicecall.settings.translations 1.0

Column {
    function resetCounters() {
        voiceUsage.resetCounters()
    }

    property bool clearingCounters

    width: parent.width

    SectionHeader {
        //: Call counters section header
        //% "Call counters"
        text: qsTrId("settings_voicecall-he-call_duration")
    }

    Label {
        x: Theme.horizontalPageMargin
        color: Theme.secondaryHighlightColor

        //% "Dialled calls: %1"
        text: qsTrId("settings_voicecall-la-dialled_calls").arg(Format.formatDuration(
                                                                    clearingCounters ? 0 : voiceUsage.dialledCounter,
                                                                    Formatter.DurationLong))
    }

    Label {
        x: Theme.horizontalPageMargin
        color: Theme.secondaryHighlightColor

        //% "Received calls: %1"
        text: qsTrId("settings_voicecall-la-received_calls").arg(Format.formatDuration(
                                                                      clearingCounters ? 0 : voiceUsage.receivedCounter,
                                                                      Formatter.DurationLong))
    }

    Label {
        x: Theme.horizontalPageMargin
        color: Theme.secondaryHighlightColor

        //% "All calls: %1"
        text: qsTrId("settings_voicecall-la-all_calls").arg(Format.formatDuration(
                                                                clearingCounters ? 0 : voiceUsage.allCounter,
                                                                Formatter.DurationLong))
    }

    WallClock {
        id: wallclock

        enabled: voiceUsage.timerActive && Qt.application.active
        updateFrequency: WallClock.Second
    }

    DBusInterface {
        id: voiceUsage

        property int dialledCounter: dialledDuration + ongoingDialledDuration + (activeCallIncoming ? 0 : elapsedTime)
        property int receivedCounter: receivedDuration + ongoingReceivedDuration + (activeCallIncoming ? elapsedTime : 0)
        property int allCounter: dialledCounter + receivedCounter

        property int dialledDuration: 0
        property int receivedDuration: 0
        property int ongoingDialledDuration: 0
        property int ongoingReceivedDuration: 0
        property double updateTime: 0
        property double elapsedTime: wallclock.enabled ? (wallclock.time.valueOf() - updateTime) / 1000 : 0
        property bool timerActive: false
        property bool activeCallIncoming: false

        function totalIncomingCallDurationChanged() {
            getTotalIncomingCallDuration();
        }

        function totalOutgoingCallDurationChanged() {
            getTotalOutgoingCallDuration();
        }

        function voiceCallsChanged() {
            updateOngoingCallDuration();
        }

        function activeVoiceCallChanged() {
            updateOngoingCallDuration();
        }

        function updateOngoingCallDuration() {
            updateTime = wallclock.time.valueOf();

            // Check active call and stop timer.
            var activeVoiceCall = getProperty("activeVoiceCall");
            if (activeVoiceCall === "")
                timerActive = false;

            // Get call duration for all ongoing calls.
            var voiceCalls = getProperty("voiceCalls");
            ongoingDialledDuration = 0;
            ongoingReceivedDuration = 0;
            for (var i = 0; i < voiceCalls.length; ++i) {
                voicecall.path = "/calls/" + voiceCalls[i];
                var incoming = voicecall.getProperty("isIncoming");
                var duration = voicecall.getProperty("duration");
                if (incoming)
                    ongoingReceivedDuration += duration;
                else
                    ongoingDialledDuration += duration;

                // Start timer if this is the active call.
                if (activeVoiceCall === voiceCalls[i]) {
                    activeCallIncoming = incoming;
                    var status = voicecall.getProperty("status");
                    // start timer only if active voice call is in active state
                    timerActive = (status === 1);
                }
            }
        }

        service: "org.nemomobile.voicecall"
        path: "/"
        iface: "org.nemomobile.voicecall.VoiceCallManager"
        signalsEnabled: Qt.application.active
        onSignalsEnabledChanged: {
            if (signalsEnabled) {
                getTotalIncomingCallDuration();
                getTotalOutgoingCallDuration();
                updateOngoingCallDuration();
            } else {
                timerActive = false;
            }
        }

        function getTotalIncomingCallDuration() {
            receivedDuration = getProperty("totalIncomingCallDuration");
        }

        function getTotalOutgoingCallDuration() {
            dialledDuration = getProperty("totalOutgoingCallDuration");
        }

        function resetCounters() {
            typedCall("resetCallDurationCounters", undefined);
        }
    }

    DBusInterface {
        id: voicecall

        service: "org.nemomobile.voicecall"
        iface: "org.nemomobile.voicecall.VoiceCall"
    }

    DBusInterface {
        id: active

        service: "org.nemomobile.voicecall"
        iface: "org.nemomobile.voicecall.VoiceCall"
        path: "/calls/active"
        signalsEnabled: Qt.application.active

        function statusChanged() {
            var status = getProperty("status");
            // start timer only if active voice call is in active state
            voiceUsage.timerActive = (status === 1);
        }
    }
}
