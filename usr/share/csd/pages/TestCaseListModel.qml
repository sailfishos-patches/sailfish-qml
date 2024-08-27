/*
 * Copyright (c) 2020 Open Mobile Platform LLC
 * Copyright (c) 2016 - 2023 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import QtQuick.LocalStorage 2.0
import Csd 1.0
import "."

ListModel {
    id: testCaseList

    property bool autoTests
    property int testMode: Features.AllTests

    // displayName  test name displayed in the UI
    // url          String that uniquely identifies the test. This value is used to determine the
    //              test QML page testToolPages/<url>.qml and is used as the key when storing test
    //              results in the sqlite database (see below).
    // group        Group name that the test is displayed under in the UI.
    // supported    whether the feature is supported by hardware under test.
    // result       Result of the last test run

    property var urls: [
        "TouchSelfTest", "VerificationTouch", "VerificationMultiTouch", "VerificationLcd",
        "VerificationLcdBacklight", "VerificationLightSensor", "VerificationProxSensor", "VerificationGyroAndGSensor",
        "VerificationEcompass", "VerificationHallDetect", "VerificationFingerprint", "VerificationAudio1Mic",
        "VerificationAudio2Mic", "AudioPlayMusicLoudspeaker", "AudioPlayStereoLoudspeaker", "AudioPlayMusicReceiver",
        "VerificationHeadsetDetect", "VerificationHeadsetButtons", "VerificationHeadset", "AudioPlayMusicHeadset",
        "VerificationVideoPlayback", "VerificationVideoPlaybackVibrator",
        "VerificationFrontCamera", "VerificationFrontCameraReboot", "VerificationBackCamera", "VerificationFrontBackCamera",
        "VerificationWifi", "VerificationBluetooth", "VerificationNfc", "VerificationGpsRadio", "VerificationGpsLock", "VerificationCellInfo",
        "VerificationFmRadio",
        "Verification2G", "Verification3G", "Verification4G", "Verification5G",
        "VerificationBattery", "VerificationUsbCharging",
        "VerificationDischarging", "VerificationBatteryResistance", "VerificationLED",
        "VerificationButtonBacklight",
        "VerificationVibrator", "VerificationSim", "VerificationSdCard", "VerificationKey",
        "VerificationUsbOtg",
        "VerificationSuspend", "VerificationReboot",
        "VerificationCalibration",
        "VerificationMacAddresses"
    ]

    function updateTestList() {
        clear()
        for (var i = 0; i < urls.length; i++) {
            var url = urls[i]
            // Skip empty urls
            if (url && feature(url)) {
                append({"url": url,
                        "group": group(url),
                        "displayName": displayName(url),
                        "supported": true,
                        "result": _getDbResult(url),
                        "passes": parseInt(_getDbResult(url + "_passes")),
                        "failures": parseInt(_getDbResult(url + "_failures"))
                    })
            }
        }
    }

    function clearResults() {
        log("", "Clearing test results")
        for (var i = 0; i < urls.length; ++i) {
            // Skip empty urls
            var url = urls[i]
            var modelIndex = url ? _indexForUrl(url) : -1
            if (modelIndex >= 0) {
                set(modelIndex, {
                    "result": FactoryUtils.Untest,
                    "passes": 0,
                    "failures": 0
                })
            }
        }
        var db = _getDatabase()
        db.transaction(function(tx) {
            tx.executeSql('DROP TABLE settings;')
        })
        _initializeDb()
    }

    function _indexForUrl(url) {
        return ListModelRefCounter.indexForUrl(testCaseList, url)
    }

    function setResult(url, passFail) {
        var modelList = ListModelRefCounter.modelIndexForUrl(url)
        var dbUpdated = false
        for (var i = 0; i < modelList.length; ++i) {
            var index = modelList[i].index
            var model = modelList[i].model

            // For run-in-tests write success/pass count to database.
            if (model.testMode === Features.RunInTests) {
                // Let's do not update database scheme rather use text field.
                var object = model.get(index)
                var value = 0
                var propertyName = passFail ? "passes" : "failures"
                value = parseInt(object[propertyName]) + 1

                // Count passes and failures.
                if (!dbUpdated) {
                    _setDbResult(url + "_" + propertyName, value)
                }
                model.setProperty(index, propertyName, value)
            }

            if (!dbUpdated) {
                _setDbResult(url, passFail)
                dbUpdated = true
            }
            model.setProperty(index, "result", passFail ? FactoryUtils.Pass : FactoryUtils.Fail)
        }
    }

    function getTestParameter(url, parameter, defaultValue) {
        var value = _getDbOption(url + "." + parameter)
        return value ? value : defaultValue
    }

    function setTestParameter(url, parameter, value) {
        return _setDbOption(url + "." + parameter, value)
    }

    function getOption(option) {
        return _getDbOption(option)
    }

    function setOption(option, value) {
        return _setDbOption(option, value)
    }

    function log(url, message) {
        if (url === "" || _indexForUrl(url) >= 0) {
            var now = new Date
            var runMode
            switch (testMode) {
            case Features.FactoryTests:
                runMode = 'f'
                break
            case Features.RunInTests:
                runMode = 'r'
                break
            case Features.AllTests:
                runMode = 'a'
                break
            default:
                runMode = '?'
            }
            _logMessage(now, runMode, url, message)
            console.log(now, runMode, url, message)
        }
    }

    Component.onCompleted: {
        _initializeDb()
        updateTestList()
        ListModelRefCounter.addModel(testCaseList)
    }

    Component.onDestruction: ListModelRefCounter.releaseModel(testCaseList)

    function displayName(url) {
        switch (url) {
        case "TouchSelfTest":
            //% "Touch IC self test"
            return qsTrId("csd-li-touch_panel_hardware")
        case "VerificationTouch":
            //% "Surround touch"
            return qsTrId("csd-li-surround_touch")
        case "VerificationMultiTouch":
            //% "Multi-touch"
            return qsTrId("csd-li-multi_touch")
        case "VerificationLcd":
            //% "LCD"
            return qsTrId("csd-li-lcd")
        case "VerificationLcdBacklight":
            //% "LCD backlight"
            return qsTrId("csd-li-lcd_backlight")
        case "VerificationLightSensor":
            //% "Light sensor"
            return qsTrId("csd-li-light_sensor")
        case "VerificationProxSensor":
            //% "Proximity sensor"
            return qsTrId("csd-li-proximity_sensor")
        case "VerificationGyroAndGSensor":
            if (Features.supported("Gyro") && Features.supported("GSensor")) {
                //% "Gyro & Accelerometer"
                return qsTrId("csd-li-gyroscope_and_gsensor")
            }
            if (Features.supported("Gyro")) {
                //% "Gyroscope sensor"
                return qsTrId("csd-li-gyroscope_sensor")
            } else {
                //% "Accelerometer sensor"
                return qsTrId("csd-li-accelerometer_sensor")
            }
        case "VerificationEcompass":
            //% "Compass"
            return qsTrId("csd-li-compass")
        case "VerificationAudio1Mic":
            //% "Audio below microphone"
            return qsTrId("csd-li-audio_below_microphone")
        case "VerificationAudio2Mic":
            //% "Audio above microphone"
            return qsTrId("csd-li-audio_above_microphone")
        case "VerificationHeadset":
            //% "Headset recording"
            return qsTrId("csd-li-headset_recording")
        case "AudioPlayMusicLoudspeaker":
            //% "Loudspeaker playback"
            return qsTrId("csd-li-loudspeaker_playback")
        case "AudioPlayMusicReceiver":
            //% "Receiver playback"
            return qsTrId("csd-li-receiver_playback")
        case "AudioPlayMusicHeadset":
            //% "Headset playback"
            return qsTrId("csd-li-headset_playback")
        case "AudioPlayStereoLoudspeaker":
            //% "Stereo loudspeaker playback"
            return qsTrId("csd-li-stereo_loudspeaker_playback")
        case "VerificationWifi":
            //% "WLAN"
            return qsTrId("csd-li-wlan")
        case "VerificationBluetooth":
            //% "Bluetooth"
            return qsTrId("csd-li-bluetooth")
        case "VerificationNfc":
            //% "NFC"
            return qsTrId("csd-li-nfc")
        case "VerificationGpsRadio":
            //% "GPS"
            return qsTrId("csd-li-gps")
        case "VerificationGpsLock":
            //% "GPS satellite lock"
            return qsTrId("csd-li-gps_satellite_lock")
        case "VerificationCellInfo":
            //% "Cell positioning"
            return qsTrId("csd-he-cell_positioning")
        case "VerificationFrontCamera":
            //% "Front camera"
            return qsTrId("csd-li-front_camera")
        case "VerificationFrontCameraReboot":
            //% "Front camera with reboot"
            return qsTrId("csd-li-front_camera_reboot")
        case "VerificationBackCamera":
            return CsdHwSettings.backCameraFlash
                    ? //% "Main camera and flash"
                      qsTrId("csd-li-back_camera_and_flash_light")
                    : //% "Main camera"
                      qsTrId("csd-li-back_camera")
        case "VerificationFrontBackCamera":
            return CsdHwSettings.backCameraFlash ? //% "Front and back camera with flash"
                                                   qsTrId("csd-li-front_and_back_camera_with_flash_light")
                                                 : //% "Back and front camera"
                                                   qsTrId("csd-li-front_and_back_camera")
        case "VerificationBattery":
            //% "Battery"
            return qsTrId("csd-li-battery")
        case "VerificationUsbCharging":
            //% "USB charging"
            return qsTrId("csd-li-usb_charging")
        case "VerificationDischarging":
            //% "Discharging"
            return qsTrId("csd-li-discharging")
        case "VerificationBatteryResistance":
            //% "Battery resistance"
            return qsTrId("csd-li-battery_resistance")
        case "VerificationLED":
            //% "LED"
            return qsTrId("csd-li-led")
        case "VerificationButtonBacklight":
            //% "ButtonBacklight"
            return qsTrId("csd-li-button-backlight")
        case "VerificationVibrator":
            //% "Vibrator"
            return qsTrId("csd-li-vibrator")
        case "VerificationSim":
            //% "SIM card"
            return qsTrId("csd-li-sim_card")
        case "VerificationSdCard":
            //% "SD Card"
            return qsTrId("csd-li-sd_card")
        case "VerificationKey":
            //% "Key"
            return qsTrId("csd-li-key")
        case "VerificationHeadsetDetect":
            //% "Headset detection"
            return qsTrId("csd-li-headset_detection")
        case "VerificationHeadsetButtons":
            //% "Headset buttons"
            return qsTrId("csd-li-headset_buttons")
        case "VerificationUsbOtg":
            //% "USB OTG"
            return qsTrId("csd-li-usb_otg")
        case "VerificationHallDetect":
            //% "Hall sensor"
           return qsTrId("csd-li-hall_sensor")
        case "VerificationFingerprint":
            //% "Fingerprint sensor"
            return qsTrId("csd-li-fingerprint-sensor")
        case "VerificationVideoPlayback":
            //% "Video playback"
            return qsTrId("csd-li-video_playback")
        case "VerificationVideoPlaybackVibrator":
            //% "Video playback and vibration"
            return qsTrId("csd-li-video_playback_vibration")
        case "VerificationFmRadio":
            //% "FM Radio"
            return qsTrId("csd-li-fm_radio")
        case "VerificationSuspend":
            //% "Suspend"
            return qsTrId("csd-li-suspend")
        case "VerificationReboot":
            //% "Reboot"
            return qsTrId("csd-li-reboot")
        case "Verification2G":
            return "2G"
        case "Verification3G":
            return "3G"
        case "Verification4G":
            return "4G"
        case "Verification5G":
            return "5G"
        case "VerificationCalibration":
            //% "Calibration check"
            return qsTrId("csd-li-calibration")
        case "VerificationMacAddresses":
            //% "MAC Address check"
            return qsTrId("csd-li-mac-address")
        default:
            console.log("No display name for url", url)
        }
    }
    function group(url) {
        switch (url) {
        case "TouchSelfTest":
        case "VerificationTouch":
        case "VerificationMultiTouch":
        case "VerificationLcd":
        case "VerificationLcdBacklight":
            //% "Display and touch screen"
            return qsTrId("csd-he-display_and_touch")
        case "VerificationLightSensor":
        case "VerificationProxSensor":
        case "VerificationGyroAndGSensor":
        case "VerificationEcompass":
        case "VerificationHallDetect":
        case "VerificationFingerprint":
            //% "Sensor"
            return qsTrId("csd-he-sensor")
        case "VerificationAudio1Mic":
        case "VerificationAudio2Mic":
        case "AudioPlayMusicLoudspeaker":
        case "AudioPlayStereoLoudspeaker":
        case "AudioPlayMusicReceiver":
        case "VerificationHeadsetDetect":
        case "VerificationHeadsetButtons":
        case "VerificationHeadset":
        case "AudioPlayMusicHeadset":
            //% "Audio"
            return qsTrId("csd-he-audio")
        case "VerificationVideoPlayback":
        case "VerificationVideoPlaybackVibrator":
            //% "Video"
            return qsTrId("csd-he-video")
        case "VerificationFrontCamera":
        case "VerificationFrontBackCamera":
        case "VerificationBackCamera":
            //% "Camera"
            return qsTrId("csd-he-camera")
        case "VerificationWifi":
        case "VerificationBluetooth":
        case "VerificationNfc":
        case "VerificationGpsRadio":
        case "VerificationGpsLock":
        case "VerificationCellInfo":
        case "VerificationFmRadio":
            //% "Radio"
            return qsTrId("csd-he-radio")
        case "Verification2G":
        case "Verification3G":
        case "Verification4G":
        case "Verification5G":
            //: Radio frequency function check
            //% "RF Function Check"
            return qsTrId("csd-la-he-rf-function")
        case "VerificationBattery":
        case "VerificationUsbCharging":
        case "VerificationDischarging":
        case "VerificationBatteryResistance":
            //% "Power"
            return qsTrId("csd-he-power")
        case "VerificationLED":
        case "VerificationButtonBacklight":
        case "VerificationVibrator":
        case "VerificationSim":
        case "VerificationSdCard":
        case "VerificationKey":
        case "VerificationUsbOtg":
            //% "Component"
            return qsTrId("csd-he-component")
        case "VerificationSuspend":
        case "VerificationReboot":
        case "VerificationCalibration":
        case "VerificationMacAddresses":
            //% "System state"
            return qsTrId("csd-he-system_state")
        default:
            console.log("No display name for url", url)
        }
    }

    function getTestParameters(url) {
        return testParameters[url] ? testParameters[url] : []
    }

    property var testParameters: {
        "VerificationFrontBackCamera": ["RunInTestTime"],
        "VerificationFrontCameraReboot": ["RunInTestTime"],
        "VerificationVideoPlayback": ["RunInTestTime"],
        "VerificationVideoPlaybackVibrator": ["RunInTestTime"],
        "VerificationReboot": ["RunInTestTime"],
        "VerificationSuspend": ["RunInTestTime"]
    }

    property var mapping: {
        "TouchSelfTest": [["TouchAuto"]],
        "VerificationTouch": [["Touch"]],
        "VerificationMultiTouch": [["Touch"]],
        "VerificationLcd": [["LCD"]],
        "VerificationLcdBacklight": [["Backlight"]],
        "VerificationLightSensor": [["LightSensor"]],
        "VerificationProxSensor": [["ProxSensor"]],
        "VerificationGyroAndGSensor": [undefined, ["Gyro", "GSensor"]],
        "VerificationEcompass": [["ECompass"]],
        "VerificationAudio1Mic": [["AudioMic1"]],
        "VerificationAudio2Mic": [["AudioMic2"]],
        "AudioPlayMusicLoudspeaker": [["Loudspeaker"]],
        "AudioPlayMusicReceiver": [["Receiver"]],
        "VerificationHeadset": [["Headset"]],
        "AudioPlayStereoLoudspeaker": [["StereoLoudspeaker"]],
        "AudioPlayMusicHeadset": [["Headset"]],
        "VerificationHeadsetDetect": [["Headset"]],
        "VerificationHeadsetButtons": [["Headset"]],
        "VerificationWifi": [["Wifi"]],
        "VerificationBluetooth": [["Bluetooth"]],
        "VerificationNfc": [["NFC"]],
        "VerificationGpsRadio": [["GPS"]],
        "VerificationGpsLock": [["GPS"]],
        "VerificationCellInfo": [["CellInfo"]],
        "VerificationFrontCamera": [["FrontCamera"]],
        "VerificationBackCamera": [["BackCamera"]],
        "VerificationBattery": [["Battery"]],
        "VerificationDischarging": [["Battery"]],
        "VerificationBatteryResistance": [["Battery"]],
        "VerificationUsbCharging": [["UsbCharging"]],
        "VerificationLED": [["LED"]],
        "VerificationButtonBacklight": [["ButtonBacklight"]],
        "VerificationVibrator": [["Vibrator"]],
        "VerificationSim": [["SIM"]],
        "VerificationSdCard": [["SDCard"]],
        "VerificationKey": [["Key"]],
        "VerificationUsbOtg": [["UsbOtg"]],
        "VerificationHallDetect": [["Hall"]],
        "VerificationFingerprint": [["Fingerprint"]],
        "VerificationFmRadio" : [["FmRadio"]],
        "VerificationSuspend": [["Suspend"]],
        "VerificationReboot": [["Reboot"]],
        "VerificationVideoPlayback": [["VideoPlayback"]],
        "VerificationVideoPlaybackVibrator": [["VideoPlayback", "Vibrator"]],
        "Verification2G": [["CellularData"]],
        "Verification3G": [["CellularData"]],
        "Verification4G": [["CellularData"]],
        "Verification5G": [["CellularData", "Cellular5G"]],
        "VerificationCalibration": [["Calibration"]],
        "VerificationMacAddresses": [undefined, ["Bluetooth", "Wifi"]],
    }

    // Alternative mappings used for some run-in tests
    property var alternativeMapping: {
        "AudioPlayMusicLoudspeaker": [["StereoLoudspeaker"]],
        "VerificationFrontBackCamera": [["FrontCamera", "BackCamera"]],
        "VerificationFrontCameraReboot": [["FrontCamera"]],
    }

    function feature(url) {
        if (mapping[url] === undefined && alternativeMapping[url] === undefined) {
            console.log("Unknown feature support for url", url, "test disabled!")
            return false
        }

        var supported = testSupported(mapping, url)

        if (autoTests)
            return supported && auto_mapping[url] !== undefined

        switch (testMode) {
        case Features.FactoryTests:
            return supported && Features.factoryTestEnabled(url)
        case Features.RunInTests:
            // Argument should be just url
            return (supported || testSupported(alternativeMapping, url)) && Features.runInTestEnabled(url)
        case Features.AllTests:
            return supported
        default:
            console.log("Unknown TestMode", testMode)
            return false
        }
    }

    // a test is supported if *any* of its listed features are supported
    function testSupported(featureMapping, url) {
        var features = featureMapping[url]
        if (features === undefined) {
            return false
        }
        var allOf = features[0]
        var anyOf = features[1]
        if (allOf !== undefined) {
            // all of the listed features must be supported
            for (var i = 0; i < allOf.length; i++) {
                if (!Features.supported(allOf[i], url)) {
                    return false
                }
            }
        }
        if (anyOf !== undefined) {
            // at least of the listed features must be supported
            for (var i = 0; ; i++) {
                if (i == anyOf.length) {
                    return false
                }
                if (Features.supported(anyOf[i], url)) {
                    break;
                }
            }
        }
        return true
    }

    property var auto_mapping: {
        "VerificationWifi": "1",
        "VerificationBluetooth": "1",
        "VerificationBattery": "1",
        "VerificationGpsRadio": "1",
        "VerificationSim": "1",
        "VerificationSdCard": "1",
        "VerificationUsbCharging": "1",
        "VerificationCalibration": "1",
        "VerificationMacAddresses": "1"
    }

    function _getDatabase() {
        return LocalStorage.openDatabaseSync("CSD", "1.0", "StorageDatabase", 100000)
    }

    // At the start of the application, we can initialize the tables we need if they
    // haven't been created yet
    function _initializeDb() {
        var db = _getDatabase()
        db.transaction(function(tx) {
            // Create the settings table if it doesn't already exist
            // If the table exists, this is skipped
            tx.executeSql('CREATE TABLE IF NOT EXISTS settings(setting TEXT UNIQUE, value TEXT)')

            // Create the options table if it doesn't already exist
            tx.executeSql('CREATE TABLE IF NOT EXISTS options(option TEXT UNIQUE, value TEXT)')

            /* Create the log table.

               timestamp - timestamp of the log event
               runmode - the mode in which the test was run when the log event occurred.
                         possible values are:
                             individual test ('i')
                             advanced tests ('a')
                             run-in ('r')
               url - the url of the test
               message - the log message

               The timestamp may not be unique. To get a chronologically ordered list of log events
               use the sqlite built-in ROWID column:

                   SELECT * FROM log ORDER BY ROWID;
            */
            tx.executeSql('CREATE TABLE IF NOT EXISTS log(timestamp INTEGER, runmode TEXT, url TEXT, message TEXT)')
        })
    }

    function _setDbResult(setting, value) {
        var db = _getDatabase()
        var res = ""
        db.transaction(function(tx) {
            var rs = tx.executeSql('INSERT OR REPLACE INTO settings VALUES (?,?);', [setting, value])
            if (rs.rowsAffected > 0)
                res = "OK"
            else
                res = "Error"
        })

        // The function returns “OK” if it was successful, or “Error” if it wasn't
        return res
    }

    function _getDbResult(setting) {
        var db = _getDatabase()
        var res= ""
        db.transaction(function(tx) {
            var rs = tx.executeSql('SELECT value FROM settings WHERE setting=?;', [setting])
            if (rs.rows.length > 0)
                res = rs.rows.item(0).value
            else
                res = FactoryUtils.Untest
        })
        return res
    }

    function _getDbOption(option) {
        var db = _getDatabase()
        var result
        db.transaction(function(tx) {
            var rs = tx.executeSql('SELECT value FROM options WHERE option=?;', [option])
            if (rs.rows.length > 0)
                result = rs.rows.item(0).value
        })
        return result
    }

    function _setDbOption(option, value) {
        var db = _getDatabase()
        var result
        db.transaction(function(tx) {
            var rs = tx.executeSql('INSERT OR REPLACE INTO options VALUES (?,?);', [option, value])
            if (rs.rowsAffected > 0)
                result = "OK"
            else
                result = "Error"
        })
        return result
    }

    function _logMessage(stamp, runMode, url, message) {
        var db = _getDatabase()
        db.transaction(function(tx) {
            tx.executeSql('INSERT INTO log VALUES(?,?,?,?);', [stamp, runMode, url, message])
        })
    }
}
