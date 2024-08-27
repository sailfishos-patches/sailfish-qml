/*
 * Copyright (c) 2022 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.startupwizard 1.0

WizardPostAccountCreationDialog {
    endDestination: _pageAfterAccountSetup
    endDestinationAction: PageStackAction.Replace
    endDestinationReplaceTarget: null
    backNavigation: false
}
