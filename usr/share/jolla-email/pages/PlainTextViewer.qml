/*
 * Copyright (c) 2013 – 2019 Jolla Ltd.
 * Copyright (c) 2019 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.TextLinking 1.0
import Nemo.Email 0.1
import org.nemomobile.configuration 1.0

SilicaFlickable {
    id: flickable

    property EmailMessage email
    property bool waitToAppend
    property alias portrait: messageViewHeader.portrait
    property alias attachmentsModel: messageViewHeader.attachmentsModel
    property alias isOutgoing: messageViewHeader.isOutgoing
    property bool isLocalFile

    signal removeRequested
    signal needToSendReadReceipt

    function loadBody() {
        textModel.clear()
        contentY = 0
        textView.emailBody = email.body
        textView.appendText(20000)
        if (!email.read && email.requestReadReceipt) {
            needToSendReadReceipt()
        }

        email.read = true
    }

    function show(message) {
        // check if initial text is already set
        // show messages can be called on PageStatus.Activating
        // and when messageId changes
        if (!textView.textSet) {
            email = message
            loadBody()
        }
        visible = true
    }

    contentHeight: messageViewHeader.height + textView.height + Theme.paddingLarge * 2

    onAtYEndChanged: {
        if (atYEnd && textView.emailBody.length && textView.textSet) {
            if (quickScrollAnimating) {
                waitToAppend = true
            } else {
                // Append next max 10000 chars from the body
                textView.appendText(10000)
            }
        }
    }

    onQuickScrollAnimatingChanged: {
        if (!quickScrollAnimating && waitToAppend) {
            waitToAppend = false
            textView.appendText(10000)
        }
    }

    Rectangle {
        x: flickable.contentX
        y: messageViewHeader.height

        width: flickable.contentWidth
        height: Math.max(flickable.height, contentHeight) - y
        color: "white"
    }

    MessageViewPullDown {
        onRemoveRequested: flickable.removeRequested()
        visible: !flickable.isLocalFile
    }

    MessageViewHeader {
        id: messageViewHeader
        width: parent.width
        email: flickable.email
    }

    Column {
        id: textView

        property string emailBody
        property bool textSet

        anchors {
            top: messageViewHeader.bottom
            left: parent.left
            right: parent.right
            margins: Theme.horizontalPageMargin
        }

        function appendText(maxLength) {
            var lineBreak = -1
            if (emailBody.length > maxLength) {
                lineBreak = emailBody.lastIndexOf('\n', maxLength)
            }
            var cutIndex = (lineBreak < maxLength - 200) ? maxLength : lineBreak
            textModel.append({"text": emailBody.substring(0, cutIndex)})
            if (!textView.textSet) {
                textView.textSet = true
            }
            emailBody = emailBody.substring(cutIndex)
        }

        Repeater {
            model: ListModel { id: textModel }
            delegate: LinkedText {
                width: parent ? parent.width : 0
                color: "black"
                linkColor: Theme.highlightBackgroundColor
                font.pixelSize: Screen.sizeCategory >= Screen.Large ? Theme.fontSizeSmall : Theme.fontSizeExtraSmall
                wrapMode: Text.Wrap
                plainText: modelData
            }
        }
    }

    VerticalScrollDecorator { color: Theme.highlightBackgroundColor }
}
