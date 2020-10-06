/****************************************************************************
**
** Copyright (C) 2017-2020 Elros https://github.com/elros34
**               2020 Rinigus https://github.com/rinigus
**               2012 Digia Plc and/or its subsidiary(-ies).
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

ApplicationWindow {
    id: app

    initialPage: MainPage {}
    cover: undefined
    allowedOrientations: defaultAllowedOrientations
    _defaultPageOrientations: allowedOrientations

    property bool darkStyle: Theme.colorScheme === Theme.LightOnDark
    property bool ready: py && py.ready
    property var  py

    Connections {
        target: runner
        onExit: {
            console.log("Skipping quit as it will hang the window. Proper exit is needed");
            // Qt.quit();
        }
    }

    Component.onCompleted: {
        settings.dark = darkStyle;
        if (modeSettings) {
            var pyComponent = Qt.createComponent("Python.qml");
            if (pyComponent.status !== Component.Ready) {
                console.warn("Error loading Python: " +  pyComponent.errorString());
                return;
            }
            app.py = pyComponent.createObject(app);
        } else {
            settings.applyTheme(runner.program);
            runner.start();
        }
    }

    onDarkStyleChanged: settings.dark = darkStyle

    onReadyChanged: {
        if (ready && modeSettings)
            initialPage.initSettings();
    }
}
