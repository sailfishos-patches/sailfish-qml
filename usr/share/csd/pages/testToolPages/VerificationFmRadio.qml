/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.0
import Csd 1.0
import ".."

CsdTestPage {
    id: page

    property double defaultFrequency: CsdHwSettings.defaultFmRadioFrequency
    property bool _testing

    function startTest() {
        _testing = true
        route.fmRadio = true
        // Radio frequency is in Hz
        radio.frequency = defaultFrequency * 1000000
        radio.start()
    }

    AudioRoute {
        id: route

        onWiredOutputConnectedChanged: {
            if (_testing && !wiredOutputConnected) {
                setTestResult(false)
                testCompleted(true)
            }
        }
    }

    Radio {
        id: radio

        band: Radio.FM

        onFrequencyChanged: {
            // Radio frequency is in Hz
            freqText.text = radio.frequency / 1000000 + " MHz"
        }

        function updateStatus(seek) {
            if (radio.searching) {
                //% "Seeking..."
                statusText.text = qsTrId("csd-la-audio_fm_radio_seeking")
            } else {
                if (radio.state == Radio.ActiveState) {
                    if (seek) {
                        //% "Tuned to radio station"
                        statusText.text = qsTrId("csd-la-audio_fm_radio_tuned_to_station")
                    } else {
                        //% "Radio on"
                        statusText.text = qsTrId("csd-la-audio_fm_radio_on")
                    }
                } else {
                    //% "Radio off"
                    statusText.text = qsTrId("csd-la-audio_fm_radio_off")
                }
            }
        }

        onSearchingChanged: updateStatus(true)

        onStateChanged: updateStatus(false)
    }

    BottomButton {
        id: startButton
        visible: !_testing
        enabled: route.wiredOutputConnected
        //% "Start"
        text: qsTrId("csd-la-start")
        onClicked: startTest()
    }

    Column {
        width: parent.width
        spacing: Theme.paddingLarge
        CsdPageHeader {
            //% "FM Radio"
            title: qsTrId("csd-he-fm_radio")
        }

        DescriptionItem {
            visible: !_testing
            //% "1. Make sure headset is connected.<br>2. Press 'Start' button.<br>3. Seek frequency with 'Seek up' and 'Seek down' buttons."
            text: qsTrId("csd-la-audio_fm_radio_description")
        }
    }

    Label {
        id: statusText
        visible: _testing
        anchors.bottom: freqText.top
        x: Theme.paddingLarge
        font.pixelSize: Theme.fontSizeLarge
        width: parent.width-(6*Theme.paddingLarge)
        wrapMode: Text.WordWrap
    }

    Label {
        id: freqText
        anchors.bottom: radioControls.top
        visible: _testing
        x: Theme.paddingLarge
        font.pixelSize: Theme.fontSizeLarge
        width: parent.width-(6*Theme.paddingLarge)
        wrapMode: Text.WordWrap
    }

    Column {
        id: radioControls
        anchors.centerIn: parent
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: Theme.paddingLarge
        spacing: Theme.paddingLarge*1
        visible: _testing

        Button {
            //% "Turn on"
            text: qsTrId("csd-la-audio_fm_radio_turn_on")
            onClicked: {
                if (radio.state == Radio.StoppedState) {
                    //% "Opening device..."
                    statusText.text = qsTrId("csd-la-audio_fm_radio_opening_device")
                    radio.start()
                }
            }
        }

        Button {
            //% "Turn off"
            text: qsTrId("csd-la-audio_fm_radio_turn_off")
            onClicked: {
                if (radio.state == Radio.ActiveState) {
                    //% "Closing device..."
                    statusText.text = qsTrId("csd-la-audio_fm_radio_closing_device")
                    radio.stop()
                }
            }
        }

        Button {
            //% "Seek up"
            text: qsTrId("csd-la-audio_fm_radio_seek_up")
            onClicked: {
                radio.scanUp()
            }
        }

        Button {
            //% "Seek down"
            text: qsTrId("csd-la-audio_fm_radio_seek_down")
            onClicked: {
                radio.scanDown()
            }
        }
    }

    Label {
        id: stepText

        visible: _testing
        anchors.top: radioControls.bottom
        x: Theme.paddingLarge
        font.pixelSize: Theme.fontSizeLarge
        width: parent.width-(6*Theme.paddingLarge)
        wrapMode: Text.WordWrap
        //% "Is radio playing from headset?"
        text: qsTrId("csd-la-is_radio_playing_from_headset")
    }

    ButtonLayout {
        anchors {
            top: stepText.bottom
            topMargin: Theme.paddingLarge
            horizontalCenter: parent.horizontalCenter
        }
        rowSpacing: Theme.paddingLarge*3
        visible: _testing

        PassButton {
            id: passButton
            onClicked: {
                radio.stop()
                setTestResult(true)
                testCompleted(true)
            }
        }
        FailButton {
            id: failButton
            onClicked: {
                radio.stop()
                setTestResult(false)
                testCompleted(true)
            }
        }
    }
}
