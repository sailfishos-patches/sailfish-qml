/****************************************************************************************
** Copyright (c) 2018 – 2023 Jolla Ltd.
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

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.FileManager 1.0
import Nemo.FileManager 1.0

BusyView {
    id: root

    property alias model: archiveModel
    property alias path: archiveModel.path
    property alias archiveFile: archiveModel.archiveFile
    property alias fileName: archiveModel.fileName
    property string baseExtractionDirectory: StandardPaths.download

    signal archiveExtracted(string containingFolder)
    signal showInfo(string info)

    function extractAllFiles(targetPath) {
        var target = _buildExtractionDirectory(false, true, model.baseName)
        return archiveModel.extractAllFiles(target)
    }

    function extractFile(fileName, isDir) {
        var targetDir = _buildExtractionDirectory(isDir, false, fileName)
        return archiveModel.extractFile(fileName, targetDir)
    }

    function appendPath(fileName) {
        return archiveModel.appendPath(fileName)
    }

    function _buildExtractionDirectory(isDir, isArchive, dirName) {
        if (isArchive || isDir) {
            return baseExtractionDirectory + "/" + dirName
        } else {
            return baseExtractionDirectory
        }
    }

    // Grace timer
    Timer {
        id: graceTimer
        interval: 500
        running: model.extracting
    }

    busy: model.extracting && !graceTimer.running
    enabled: busy
    //% "Extracting"
    text: qsTrId("filemanager-la-extracting")

    ArchiveModel {
        id: archiveModel
        autoRename: true
        onErrorStateChanged: {
            switch (errorState) {
            case ArchiveModel.ErrorUnsupportedArchiveFormat:
                //% "Unsupported archive format"
                showInfo(qsTrId("filemanager-la-unsupported_archive_format"))
                break
            case ArchiveModel.ErrorArchiveNotFound:
                //% "Archive file is not found"
                showInfo(qsTrId("filemanager-la-archive_not_found"))
                break
            case ArchiveModel.ErrorArchiveOpenFailed:
                //% "Opening archive failed"
                showInfo(qsTrId("filemanager-la-opening_archive_failed"))
                break
            case ArchiveModel.ErrorArchiveExtractFailed:
                //% "Extract failed"
                showInfo(qsTrId("filemanager-la-extract_failed"))
                break
            case ArchiveModel.ErrorExtractingInProgress:
                //% "Extracting in progress"
                showInfo(qsTrId("filemanager-la-extracting_in_progress"))
                break
            }
        }

        onFilesExtracted: {
            if (isDir) {
                //% "Directory %1 extracted"
                showInfo(qsTrId("filemanager-la-directory_extracted").arg(entryName))
            } else if (entries && entries.length == 1) {
                //% "Extracted %1"
                showInfo(qsTrId("filemanager-la-file_extracted").arg(entryName))
            } else {
                //% "%1 extracted"
                showInfo(qsTrId("filemanager-la-archive_extracted").arg(fileName))
                root.archiveExtracted(path)
            }
        }
    }
}
