/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Policy 1.0
import com.jolla.settings.system 1.0
import org.nemomobile.configuration 1.0
import QtMultimedia 5.4
import Csd 1.0
import ".."

CameraTestPage {
    id: page

    focusBeforeCapture: backFaceCameraActive
    imagePreview.mirror: !backFaceCameraActive

    viewfinderResolution: viewfinderResolution.value
    imageCaptureResolution: backFaceCameraActive ? primaryImageResolution.value : secondaryImageResolution.value
    switchBetweenFrontAndBack: true

    Binding {
        target: videoOutput.source
        property: "flash.mode"
        value: CsdHwSettings.backCameraFlash ? Camera.FlashOn : Camera.FlashOff
    }

    ConfigurationValue {
        id: viewfinderResolution
        key: "/apps/jolla-camera/primary/image/viewfinderResolution"
    }

    ConfigurationValue {
        id: primaryImageResolution
        key: "/apps/jolla-camera/primary/image/imageResolution"
    }

    ConfigurationValue {
        id: secondaryImageResolution
        key: "/apps/jolla-camera/secondary/image/imageResolution"
    }

    PolicyValue {
        id: cameraPolicy
        policyType: PolicyValue.CameraEnabled
    }

    CsdPageHeader {
        id: header
        wrapMode: Text.NoWrap

        //% "Back camera"
        title: backFaceCameraActive ? qsTrId("csd-he-back_camera") :
                                      //% "Front camera"
                                      qsTrId("csd-he-front_camera")
    }

    DisabledByMdmBanner {
        id: mdmBanner
        anchors.top: header.bottom
        active: !cameraPolicy.value
        Timer {
            id: disabledByMdmFailTimer
            interval: 2500
            running: true
            onTriggered: {
                if (mdmBanner.active) {
                    setTestResult(false)
                    testCompleted(true)
                }
            }
        }
    }
}
