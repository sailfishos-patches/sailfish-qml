/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Policy 1.0
import Nemo.FileManager 1.0
import Nemo.Configuration 1.0
import org.nemomobile.systemsettings 1.0
import org.nemomobile.voicecall 1.0 as VoiceCall
import com.jolla.voicecall.settings.translations 1.0

Column {
    width: parent.width

    property QtObject recordingsModel: recordingsModelLoader.status == Loader.Ready ? recordingsModelLoader.item : null

    property var status: pageStack.currentPage.status
    onStatusChanged: {
        if (status == PageStatus.Active && !recordingsModelLoader.sourceComponent) {
            recordingsModelLoader.asynchronous = true
            recordingsModelLoader.sourceComponent = recordingsModelComponent
        }
    }

    function showRecordingsImmediately() {
        recordingsModelLoader.sourceComponent = recordingsModelComponent

        pageStack.push("RecordedCallsPage.qml", { model: Qt.binding(function() { return recordingsModelLoader.item }) }, PageStackAction.Immediate)
    }

    // Only show if call recording is available on this device
    visible: VoiceCall.VoiceCallAudioRecorder.available

    SectionHeader {
        //: Call recording section header
        //% "Call recording"
        text: qsTrId("settings_voicecall-he-call_recording")
    }

    TextSwitch {
        id: callRecordingSwitch

        onClicked: {
            if (!checked && callRecordingAcceptedConfig.value != true) {
                var obj = pageStack.animatorPush(confirmationDialog)
                obj.pageCompleted.connect(function(dialog) {
                    dialog.accepted.connect(function() {
                        callRecordingAcceptedConfig.value = true
                        callRecordingConfig.value = true
                    })
                })
            } else {
                callRecordingConfig.value = !checked
            }
        }

        //% "Call recording"
        text: qsTrId("settings_phone-la-call_recording")
        description: AccessPolicy.microphoneEnabled ?
                         //% "When the call view is active, an option is available to record the call audio."
                         qsTrId("settings_phone-la-call_recording_description") :

                         //: %1 is an operating system name without the OS suffix
                         //% "Call recording is not supported, because microphone has been disabled by %1 Device Manager"
                         qsTrId("settings_phone-la-call_recording_not_supported_disabled_by_mdm")
                             .arg(aboutSettings.baseOperatingSystemName)
        width: parent.width
        checked: AccessPolicy.microphoneEnabled && callRecordingConfig.value
        automaticCheck: false

        enabled: AccessPolicy.microphoneEnabled

        ConfigurationValue {
            id: callRecordingConfig
            key: "/jolla/voicecall/call_recording"
            defaultValue: false
        }
        ConfigurationValue {
            id: callRecordingAcceptedConfig
            key: "/jolla/voicecall/call_recording_accepted"
            defaultValue: false
        }
    }

    BackgroundItem {
        id: recordings

        height: countLabel.y + countLabel.height + Theme.paddingLarge

        Label {
            id: label
            x: Theme.horizontalPageMargin
            width: parent.width - 2*x
            y: Theme.paddingLarge
            font.pixelSize: Theme.fontSizeMedium
            color: recordings.highlighted ? Theme.highlightColor : Theme.primaryColor
            //% "Recorded calls"
            text: qsTrId("settings_phone-la-recorded_calls")
        }
        Label {
            id: countLabel
            x: Theme.horizontalPageMargin
            width: parent.width - 2*x
            y: label.y + label.height
            font.pixelSize: Theme.fontSizeExtraSmall
            color: recordings.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
            //% "%n call(s)"
            text: recordingsModel ? qsTrId("settings_voicecall-la-n_recorded_calls", recordingsModel.count) : ''
            visible: recordingsModel && recordingsModel.populated
        }

        onClicked: pageStack.animatorPush("RecordedCallsPage.qml", { model: recordingsModel })
    }

    Loader {
        id: recordingsModelLoader
    }

    Component {
        id: recordingsModelComponent

        FileModel {
            path: VoiceCall.VoiceCallAudioRecorder.recordingsDirPath
            includeDirectories: false
            nameFilters: ["*.wav"]
            sortBy: FileModel.SortByModified
            sortOrder: Qt.AscendingOrder
            active: true
        }
    }

    Component {
        id: confirmationDialog

        Dialog {
            DialogHeader {
                id: header
            }

            Column {
                x: Theme.horizontalPageMargin
                y: header.height + Theme.paddingLarge + Theme.paddingMedium
                width: parent.width - 2*x
                spacing: Theme.paddingLarge

                Label {
                    font.pixelSize: Theme.fontSizeExtraLarge
                    color: Theme.highlightColor
                    width: parent.width
                    wrapMode: Text.Wrap

                    //: Call recording confirmation header
                    //% "Call recording"
                    text: qsTrId("settings_voicecall-he-call_recording_confirmation")
                }

                Label {
                    color: Theme.highlightColor
                    width: parent.width
                    wrapMode: Text.Wrap

                    //: Call recording confirmation text
                    //% "Please confirm that recording call audio is legal in your country."
                    text: qsTrId("settings_voicecall-la-call_recording_confirmation")
                }
            }
        }
    }

    AboutSettings {
        id: aboutSettings
    }
}
