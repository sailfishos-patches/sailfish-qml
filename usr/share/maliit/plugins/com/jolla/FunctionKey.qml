/*
 * Copyright (C) 2011 Nokia Corporation and/or its subsidiary(-ies). All rights reserved.
 * Copyright (C) 2012-2013 Jolla Ltd.
 *
 * Contact: Pekka Vuorela <pekka.vuorela@jollamobile.com>
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice, this list
 * of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list
 * of conditions and the following disclaimer in the documentation and/or other materials
 * provided with the distribution.
 * Neither the name of Nokia Corporation nor the names of its contributors may be
 * used to endorse or promote products derived from this software without specific
 * prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
 * THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

import QtQuick 2.0
import com.jolla.keyboard 1.0
import Sailfish.Silica 1.0

KeyBase {
    id: aFunctKey

    property alias icon: image
    property int sourceWidth: -1
    property int sourceHeight: -1
    property bool separator
    property alias background: backgroundItem

    keyType: KeyType.FunctionKey
    leftPadding: backgroundItem.anchors.margins
    rightPadding: backgroundItem.anchors.margins
    opacity: enabled ? (pressed ? 0.6 : 1.0)
                     : 0.3
    showPopper: false

    Rectangle {
        id: backgroundItem
        color: parent.pressed ? aFunctKey.palette.highlightBackgroundColor : aFunctKey.palette.primaryColor
        opacity: parent.pressed ? 0.6 : 0.17
        radius: geometry.keyRadius
        anchors { fill: parent; margins: Theme.paddingMedium }
    }

    Icon {
        id: image
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: (aFunctKey.leftPadding - aFunctKey.rightPadding) / 2
    }

    Label {
        id: textItem
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: Math.round((aFunctKey.leftPadding - aFunctKey.rightPadding) / 2)
        width: parent.width - aFunctKey.leftPadding - aFunctKey.rightPadding - 4
        fontSizeMode: Text.HorizontalFit
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: Theme.fontSizeSmall
        font.family: Theme.fontFamily
        text: parent.caption
    }

    KeySeparator {
        visible: separator
    }
}
