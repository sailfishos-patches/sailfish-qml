/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Policy 1.0
import com.jolla.settings.system 1.0
import QtMultimedia 5.4
import org.nemomobile.configuration 1.0
import ".."

CameraTestPage {
    id: page

    imagePreview.mirror: true
    viewfinderResolution: viewfinderResolution.value
    imageCaptureResolution: imageResolution.value

    CsdPageHeader {
        id: header
        //% "Front camera"
        title: qsTrId("csd-he-front_camera")
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

    ConfigurationValue {
        id: viewfinderResolution
        key: "/apps/jolla-camera/secondary/image/viewfinderResolution"
    }

    ConfigurationValue {
        id: imageResolution
        key: "/apps/jolla-camera/secondary/image/imageResolution"
    }

    PolicyValue {
        id: cameraPolicy
        policyType: PolicyValue.CameraEnabled
    }

    Component.onCompleted: page.camera.position = Camera.FrontFace
}
