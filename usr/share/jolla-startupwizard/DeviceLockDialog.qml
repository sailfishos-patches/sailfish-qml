/*
 * Copyright (c) 2017 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.settings.system 1.0
import org.nemomobile.devicelock 1.0

MandatoryDeviceLockInputPage {
    id: mandatorySecurityCodePage

    readonly property bool mandatorySecurityCode: DeviceLock.state != DeviceLock.Unlocked
                && !lockCodeSet

    function qsTrIdString() {
        //: Shown when entering to the device lock for the first time
        //% "User data encrypted"
        QT_TRID_NOOP("startupwizard-la-user_data_encrypted")
    }

    warningText: {
        if (lockCodeSet) {
            return ""
        } else if (mandatorySecurityCode) {
            //% "A security code is required by the device policy"
            return qsTrId("startupwizard-la-mandatory_security_code_subtitle")
        } else {
            //% "Enter a security code to protect your device"
            return qsTrId("startupwizard-la-recommended_security_code_subtitle")
        }
    }

    titleText: lockCodeSet
               ? confirmTextTitle
               : enterNewSecurityCode

    //% "Skip"
    cancelText: qsTrId("startupwizard-la-skip_security_code")

    onStatusChanged: {
        if (status === PageStatus.Active) {
            switch (authorization.status) {
            case Authorization.ChallengeIssued:
                mandatorySecurityCodePage.authenticate()
                break
            case Authorization.NoChallenge:
                authorization.requestChallenge()
                break
            default:
                break
            }
        }
    }

    Connections {
        target: mandatorySecurityCodePage.authorization

        onChallengeIssued: mandatorySecurityCodePage.authenticate()
        onChallengeDeclined: mandatorySecurityCode.displayError(AuthenticationInput.SoftwareError)
    }
}
