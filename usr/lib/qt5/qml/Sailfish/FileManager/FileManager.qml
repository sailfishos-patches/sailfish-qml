/****************************************************************************************
** Copyright (c) 2018 - 2023 Jolla Ltd.
**
** All rights reserved.
**
** This file is part of Sailfish FileManager components package.
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

pragma Singleton

import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.FileManager 1.0

Item {
    id: root

    property PageStack pageStack

    /*!
    \internal

    Implementation detail for file manager
    */
    property FileManagerNotification errorNotification

    // Call before start to use
    function init(pageStack) {
        root.pageStack = pageStack
    }

    function openDirectory(properties) {
        if (!properties.hasOwnProperty("errorNotification")) {
            createErrorNotification()
            properties["errorNotification"] = root.errorNotification
        }

        return pageStack.animatorPush(Qt.resolvedUrl("DirectoryPage.qml"), properties)
    }

    function openArchive(file, path, baseExtractionDirectory, stackAction) {
        createErrorNotification()
        stackAction = stackAction || PageStackAction.Animated

        var properties = {
            archiveFile: file,
            path: path || "/",
            errorNotification: errorNotification
        }

        if (baseExtractionDirectory) {
            properties["baseExtractionDirectory"] = baseExtractionDirectory
        }

        return pageStack.animatorPush(Qt.resolvedUrl("ArchivePage.qml"), properties, stackAction)
    }

    function createErrorNotification() {
        if (!errorNotification) {
            errorNotification = errorNotificationComponent.createObject(root)
        }
    }

    function pathToUrl(path) {
        if (path.indexOf("file://") == 0) {
            console.warn("pathToUrl() argument already url:", path)
            return path
        }

        return "file://" + path.split("/").map(encodeURIComponent).join("/")
    }

    Component {
        id: errorNotificationComponent

        FileManagerNotification {}
    }
}
