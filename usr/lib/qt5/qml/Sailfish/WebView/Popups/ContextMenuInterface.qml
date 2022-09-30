/****************************************************************************
**
** Copyright (c) 2021 Open Mobile Platform LLC.
**
****************************************************************************/

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/. */

import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: root

    property string linkHref
    property string linkTitle
    property string linkProtocol
    property string imageSrc
    property string contentType
    property int viewId
    property bool downloadsEnabled: true

    property PageStack pageStack
    property QtObject tabModel: null
}
