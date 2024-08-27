/****************************************************************************************
** Copyright (c) 2013 - 2023 Jolla Ltd.
** Copyright (c) 2021 Open Mobile Platform LLC.
**
** All rights reserved.
**
** This file is part of Sailfish Transfer Engine component package.
**
** You may use this file under the terms of BSD license as follows:
**
** Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are met:
**
** 1. Redistributions of source code must retain the above copyright notice, this
**    list of conditions and the following disclaimer.
**
** 2. Redistributions in binary form must reproduce the above copyright notice,
**    this list of conditions and the following disclaimer in the documentation
**    and/or other materials provided with the distribution.
**
** 3. Neither the name of the copyright holder nor the names of its
**    contributors may be used to endorse or promote products derived from
**    this software without specific prior written permission.
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
** AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
** IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
** DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
** FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
** DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
** SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
** CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
** OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
** OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**
****************************************************************************************/
import QtQuick 2.6
import Sailfish.Silica 1.0

BackgroundItem {
    id: root

    height: nameLabel.height + subtitleLabel.height + Theme.paddingSmall*2
    _showPress: false

    HighlightImage {
        id: icon

        anchors {
            left: parent.left
            leftMargin: Theme.horizontalPageMargin
            verticalCenter: parent.verticalCenter
        }
        source: model.methodIcon
        width: Theme.iconSizeMedium
        height: Theme.iconSizeMedium
        sourceSize.width: Theme.iconSizeMedium
        sourceSize.height: Theme.iconSizeMedium
    }

    Label {
        id: nameLabel

        anchors {
            left: icon.right
            leftMargin: Theme.paddingLarge
            right: parent.right
            rightMargin: Theme.horizontalPageMargin
            verticalCenter: icon.verticalCenter
            verticalCenterOffset: subtitleLabel.text.length > 0 ? -subtitleLabel.height/2 : 0
        }
        truncationMode: TruncationMode.Fade
        text: model.displayName
        textFormat: Text.PlainText
    }

    Label {
        id: subtitleLabel

        anchors {
            top: nameLabel.bottom
            left: icon.right
            leftMargin: Theme.paddingLarge
            right: parent.right
            rightMargin: Theme.horizontalPageMargin
        }
        truncationMode: TruncationMode.Fade
        text: model.subtitle
        font.pixelSize: Theme.fontSizeExtraSmall
        color: highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
        textFormat: Text.PlainText
    }

}
