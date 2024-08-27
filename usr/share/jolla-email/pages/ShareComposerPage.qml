/****************************************************************************************
**
** Copyright (c) 2013 - 2021 Jolla Ltd.
** Copyright (c) 2021 Open Mobile Platform LLC
** All rights reserved.
**
** License: Proprietary.
**
****************************************************************************************/
import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Share 1.0
import Nemo.FileManager 1.0

ComposerPage {
    id: root

    property var shareActionConfiguration

    property var _fileResources: []
    property var _contentResources: []
    property var _tempFiles: []

    function _addAttachment(fileInfo, title) {
        var url = fileInfo.url + ""

        if (!title) {
            var fnIndex = url.lastIndexOf('/')
            if (fnIndex >= 0) {
                title = decodeURIComponent(url.slice(fnIndex+1))
            }
        }

        attachmentsModel.append({
            "url": url,
            "title": title || fileInfo.fileName,
            "mimeType": fileInfo.mimeType,
            "fileSize": fileInfo.size
        })
    }

    Component.onDestruction: {
        shareAction.removeFilesAndRmdir(_tempFiles)
    }

    ShareAction {
        id: shareAction

        Component.onCompleted: {
            shareAction.loadConfiguration(root.shareActionConfiguration)
            root.accountId = shareAction.selectedTransferMethodInfo.accountId

            var resources = shareAction.resources
            for (var i = 0; i < resources.length; ++i) {
                if (typeof resources[i] === "string") {
                    _fileResources.push(resources[i])
                } else if ((resources[i].type === "text/plain" || resources[i].type === "text/x-url")
                           && (!resources[i].name)) {
                    // Show the contents inline within the email.
                    _contentResources.push(resources[i])
                } else {
                    var tempFile = shareAction.writeContentToFile(resources[i], root.maximumAttachmentsSize)
                    if (tempFile.length > 0) {
                        _tempFiles.push(tempFile)
                        _fileResources.push(tempFile)
                    }
                }
            }
            fileInstantiator.model = _fileResources
            contentInstantiator.model = _contentResources
        }
    }

    Instantiator {
        id: fileInstantiator

        model: undefined

        delegate: FileInfo {
            id: fileInfo

            Component.onCompleted: {
                fileInfo.url = modelData
                _addAttachment(fileInfo)
            }
        }
    }

    Instantiator {
        id: contentInstantiator

        model: undefined

        delegate: FileInfo {
            id: contentFileInfo

            Component.onCompleted: {
                var content = modelData
                if (content.type !== "text/plain" && content.type !== "text/x-url") {
                    // Other file types should have been converted into temporary files by ShareAction.
                    console.warn("Unexpected inline email content type:", content.type)
                    return
                }
                if (content.type === "text/x-url" && content.linkTitle) {
                    root.emailBody += (content.linkTitle + "\n\n")
                }
                if (!!content.status) {
                    root.emailBody += (content.status + "\n\n")
                }
            }
        }
    }
}
