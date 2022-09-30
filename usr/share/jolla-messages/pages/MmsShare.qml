/*
 * Copyright (c) 2013 - 2021 Jolla Ltd.
 * Copyright (c) 2021 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Contacts 1.0
import Sailfish.Messages 1.0
import Sailfish.Telephony 1.0
import Sailfish.Share 1.0
import org.nemomobile.contacts 1.0
import org.nemomobile.thumbnailer 1.0
import org.nemomobile.ofono 1.0
import org.nemomobile.commhistory 1.0
import MeeGo.QOfono 0.2

MessageComposerPage {
    id: newMessagePage

    property var shareActionConfiguration

    property bool _showRoamingWarning: networkRegistration.isRoaming
    property bool _showRoamingError: networkRegistration.isRoaming && !connectionManager.roamingIsAllowed
    property var _selectedPerson

    property url _source
    property var _content
    property var _tempFiles: []

    allowedOrientations: Orientation.All
    recipientField.requiredProperty: PeopleModel.PhoneNumberRequired

    // Group messaging is not supported yet
    recipientField.multipleAllowed: false

    onRecipientSelectionChanged: {
        validateRecipients()
        _selectedPerson = (validatedRemoteUids.length === 1 && recipientField.selectedContacts.count === 1)
                ? recipientField.selectedContacts.get(0).person
                : null
    }

    onFocusTextInput: {
        textInput.forceActiveFocus()
    }

    topContent: [
        Label {
            x: Theme.horizontalPageMargin
            width: parent.width - 2*Theme.horizontalPageMargin
            color: Theme.secondaryHighlightColor
            font.pixelSize: Theme.fontSizeLarge
            wrapMode: Text.Wrap
            horizontalAlignment: Qt.AlignHCenter
            visible: text.length > 0

            text: _showRoamingError
                  //% "Your data settings prevent sending MMS while roaming"
                  ? qsTrId("mms-share-roaming-error")
                  : (_showRoamingWarning
                     //% "Sending MMS messages while roaming may result in data charges"
                     ? qsTrId("mms-share-roaming-warning")
                     : "")
        }
    ]

    inputContent: [
        Thumbnail {
            id: thumbnail

            y: Theme.paddingMedium
            source: newMessagePage._source
            sourceSize.width: Theme.itemSizeSmall
            sourceSize.height: Theme.itemSizeSmall
            fillMode: Thumbnail.PreserveAspectCrop
            width: Theme.itemSizeSmall
            height: Theme.itemSizeSmall

            Image {
                anchors.fill: parent
                source: visible ? "image://theme/icon-m-person" : ""
                visible: (_content != undefined) && ('type' in _content) && _content.type.indexOf('vcard') >= 0
                fillMode: Image.Pad

                Rectangle {
                    anchors.fill: parent
                    z: -1
                    color: Theme.highlightColor
                    opacity: 0.1
                }
            }
        },

        ChatTextInput {
            id: textInput

            width: newMessagePage.width - thumbnail.width
            enabled: newMessagePage.errorLabel.simErrorState.length === 0
                     && !_showRoamingError
            canSend: newMessagePage.validatedRemoteUids.length > 0

            //% "Multimedia message"
            messageTypeName: qsTrId("mms-share-la-multimedia_message")
            needsSimFeatures: true
            phoneNumberDescription: newMessagePage.validatedRemoteUids.length === 1
                                    ? MessageUtils.phoneDetailsString(newMessagePage.validatedRemoteUids[0], [_selectedPerson])
                                    : ""

            onReadyToSend: {
                if (needsSimFeatures
                        && !MessageUtils.testCanUseSim(newMessagePage.errorLabel.simErrorState)) {
                    return
                }

                var modemInfo = MessageUtils.simManager.modemSimModel.get(MessageUtils.simManager.indexOfModem(MessageUtils.voiceModemPath))
                var imsi = modemInfo ? modemInfo.imsi : ""
                if (imsi.length === 0) {
                    console.warn("Unable to find IMSI for modem:", MessageUtils.voiceModemPath)
                    return
                }

                send(imsi)
                text = ""
            }
        }
    ]

    function send(simImsi) {
        if (newMessagePage.validatedRemoteUids.length === 0) {
            console.warn("No MMS recipients found set")
            return
        }

        var attachments = [ ]

        if (_source != '') {
            attachments.push({ "contentId": "1", "path": _source })
        } else if ('data' in _content) {
            // Android does not recognize the text/vcard type
            var type = ('type' in _content) ? _content.type.replace("text/vcard", "text/x-vCard") : ""
            var name = ('name' in _content) ? _content.name : "1"
            attachments.push({ "contentId": name, "contentType": type, "freeText": _content.data })
        } else {
            console.warn("BUG: No content for MMS share message!")
        }

        if (textInput.text != '') {
            attachments.push({ "contentId": "2", "contentType": "text/plain", "freeText": textInput.text })
        }

        if (simImsi) {
            // IMSI, To, CC, BCC, Subject, Parts
            mmsHelper.sendMessage(simImsi, newMessagePage.validatedRemoteUids, [], [], "", attachments)
        } else {
            // To, CC, BCC, Subject, Parts
            mmsHelper.sendMessage(newMessagePage.validatedRemoteUids, [], [], "", attachments)
        }

        mainWindow.loadAndShowConversation(MessageUtils.telepathyAccounts.ringAccountPath,
                                           [newMessagePage.validatedRemoteUids],
                                           "",
                                           false)
    }

    Component.onDestruction: {
        shareAction.removeFilesAndRmdir(_tempFiles)
    }

    ShareAction {
        id: shareAction

        Component.onCompleted: {
            shareAction.loadConfiguration(newMessagePage.shareActionConfiguration)

            var resources = shareAction.resources
            for (var i = 0; i < resources.length; ++i) {
                if (typeof resources[i] === "string") {
                    newMessagePage._source = resources[i]
                    break
                } else {
                    var tempFile = shareAction.writeContentToFile(resources[i])
                    if (tempFile.length > 0) {
                        _tempFiles.push(tempFile)
                        newMessagePage._source = tempFile
                        break
                    }
                }
            }
        }
    }

    MmsHelper {
        id: mmsHelper
    }

    OfonoNetworkRegistration {
        id: networkRegistration
        modemPath: MessageUtils.voiceModemPath
        readonly property bool isRoaming: valid && status === "roaming"
    }

    OfonoConnMan {
        id: connectionManager
        modemPath: MessageUtils.voiceModemPath
        readonly property bool roamingIsAllowed: valid && roamingAllowed
    }
}
