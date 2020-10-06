/****************************************************************************
**
** Copyright (C) 2020 Rinigus https://github.com/rinigus
**
** This file is part of Flatpak Runner.
**
** You may use this file under the terms of the BSD license as follows:
**
** "Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are
** met:
**   * Redistributions of source code must retain the above copyright
**     notice, this list of conditions and the following disclaimer.
**   * Redistributions in binary form must reproduce the above copyright
**     notice, this list of conditions and the following disclaimer in
**     the documentation and/or other materials provided with the
**     distribution.
**   * Neither the name of the copyright holder nor the names of its
**     contributors may be used to endorse or promote products derived
**     from this software without specific prior written permission.
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
** "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
** LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
** A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
** OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
** SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
** LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
** DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
** THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
** OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
**
**
****************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import "."

Page {
    id: root

    BusyIndicator {
        id: busy
        anchors.centerIn: root
        running: false
        size: BusyIndicatorSize.Large
    }

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: column.height + 2*Theme.paddingLarge

        Column {
            id: column
            spacing: Theme.paddingLarge
            width: parent.width

            PageHeader {
                title: qsTr("Flatpak Extension")
            }

            LabelC {
                text: qsTr("Here you can refresh your Flatpak extension or remove it.")
            }

            LabelC {
                text: qsTr("Flatpak extension allows to use graphics on devices that are not " +
                           "supported by Flatpak runtime. For example, libhybris-based devices.")
            }

            SectionHeader {
                text: qsTr("Update extension")
            }

            LabelC {
                text: qsTr("Update extension to reflect currently installed libhybris and support libraries. " +
                           "This is required after update of Sailfish OS.")
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                enabled: app.ready && !busy.running
                preferredWidth: Theme.buttonWidthLarge
                text: qsTr("Update extension")
                onClicked: {
                    busy.running = true;
                    app.py.call("fpk.sync_extension", [], function() {
                        busy.running = false;
                    });
                }
            }

            SectionHeader {
                text: qsTr("Remove extension")
            }

            LabelC {
                text: qsTr("Remove extension from your home folder. Note that it will be " +
                           "created again if you start Flatpak Runner.")
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                enabled: app.ready && !busy.running
                preferredWidth: Theme.buttonWidthLarge
                text: qsTr("Remove extension")
                onClicked: {
                    busy.running = true;
                    app.py.call("fpk.remove_extension", [], function() {
                        busy.running = false;
                    });
                }
            }
       }

       VerticalScrollDecorator { flickable: flickable }
    }
}

