/*
 * Copyright (c) 2018 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Csd 1.0
import ".."

AutoTest {
    id: test

    function allMacsOk() {
        return macValidator.isMacValid("bluetooth") && macValidator.isMacValid("wireless")
    }

    function run() {
        setTestResult(allMacsOk())
    }

    MacValidator {
        id: macValidator
    }
}

