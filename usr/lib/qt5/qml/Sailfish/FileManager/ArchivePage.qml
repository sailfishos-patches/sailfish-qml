/****************************************************************************************
** Copyright (c) 2018 - 2023 Jolla Ltd.
** Copyright (c) 2019 Open Mobile Platform LLC.
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

import QtQuick 2.5
import Sailfish.Silica 1.0
import Sailfish.FileManager 1.0
import Nemo.FileManager 1.0

Page {
    id: page

    property alias path: extractor.path
    property alias archiveFile: extractor.archiveFile
    property alias fileName: extractor.fileName
    property alias baseExtractionDirectory: extractor.baseExtractionDirectory

    property string title
    property FileManagerNotification errorNotification

    signal archiveExtracted(string containingFolder)

    backNavigation: !extractor.model.extracting
    showNavigationIndicator: backNavigation

    Component.onCompleted: {
        if (!errorNotification) {
            errorNotification = errorNotificationComponent.createObject(page)
        }

        FileManager.init(pageStack)
    }

    SilicaListView {
        header: PageHeader {
            title: page.title.length > 0 ? page.title
                                         : fileName + (path != "/" ? path : "")
        }

        anchors.fill: parent
        delegate: ListItem {

            function cleanUp() {
                //% "Deleted extracted directory"
                var text = model.isDir ? qsTrId("filemanager-la-deleted_extracted_dir")
                                       : //% "Deleted extracted file"
                                         qsTrId("filemanager-la-deleted_extracted_file")
                remorseAction(text, function() {
                    FileEngine.deleteFiles(model.extractedTargetPath, true)
                    extractor.model.cleanExtractedEntry(model.fileName)
                })
            }

            width: ListView.view.width
            contentHeight: fileItem.height
            menu: contextMenu
            onClicked: {
                if (model.extracted) {
                    if (model.isDir) {
                        var directory = FileManager.openDirectory({
                                                                      path: model.extractedTargetPath,
                                                                      initialPath: StandardPaths.home,
                                                                      showDeleteFolder: true,
                                                                      //% "Extracted folder"
                                                                      description: qsTrId("filemanager-he-extracted_folder")
                                                                  })
                        directory.folderDeleted.connect(function () {
                            extractor.model.cleanExtractedEntry(model.fileName)
                        })
                    } else {
                        Qt.openUrlExternally(FileManager.pathToUrl(model.extractedTargetPath))
                    }
                } else if (model.isDir) {
                    var obj = FileManager.openArchive(archiveFile, extractor.appendPath(model.fileName), baseExtractionDirectory)
                    obj.pageCompleted.connect(function(archivePage) {
                        archivePage.archiveExtracted.connect(page.archiveExtracted)
                    })
                } else {
                    openMenu()
                }
            }

            InternalFileItem {
                id: fileItem

                compressed: !model.extracted
            }

            Component {
                id: contextMenu
                ContextMenu {
                    MenuItem {
                        visible: !model.extracted
                        //% "Extract"
                        text: qsTrId("filemanager-me-extract")
                        onClicked: extractor.extractFile(model.fileName, model.isDir)
                    }

                    MenuItem {
                        visible: model.extracted
                        //% "Delete extracted directory"
                        text: model.isDir ? qsTrId("filemanager-me-delete_extracted_dir")
                                            //% "Remove extracted file"
                                          : qsTrId("filemanager-me-delete_extracted_file")
                        onClicked: cleanUp()
                    }
                }
            }
        }

        model: extractor.model

        PullDownMenu {
            visible: extractor.model.count > 0
            busy: extractor.model.extracting

            MenuItem {
                //% "Extract all"
                text: qsTrId("filemanager-me-extract_all")
                enabled: !parent.busy
                onDelayedClick: extractor.extractAllFiles()
            }
        }

        ViewPlaceholder {
            enabled: extractor.model.count === 0
            //% "No files"
            text: qsTrId("filemanager-la-no_files")
        }
        VerticalScrollDecorator {}

        Component {
            id: errorNotificationComponent

            FileManagerNotification {}
        }
    }

    ExtractorView {
        id: extractor

        onArchiveExtracted: page.archiveExtracted(containingFolder)
        onShowInfo: {
            if (!errorNotification) {
                errorNotification = errorNotificationComponent.createObject(page)
            }
            errorNotification.show(info)
        }
    }
}
