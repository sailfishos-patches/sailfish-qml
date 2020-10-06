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

Dialog {
    id: dia

    property string flatpak
    property string name

    // Settings: List of applications
    SilicaFlickable {
        id: alist
        anchors.fill: parent
        contentHeight: column.height + 2*Theme.paddingLarge

        Column {
            id: column
            spacing: Theme.paddingLarge
            width: alist.width

            DialogHeader {
                id: header
                acceptText: qsTr("Apply")
                title: qsTr("Settings: %1").arg(dia.name)
            }

            Column {
                // theme handling
                spacing: Theme.paddingMedium
                width: alist.width

                TextSwitch {
                    id: themesw
                    text: qsTr("Override theme handling")
                    description: qsTr("Override default theme handling.")
                }

                ComboBox {
                    id: tsw
                    enabled: themesw.checked
                    label: qsTr("Theme selection")
                    description: qsTr("Set application theme.")
                    menu: ContextMenu {
                        MenuItem { text: qsTr("Automatic") }
                        MenuItem { text: qsTr("Light") }
                        MenuItem { text: qsTr("Dark") }
                        MenuItem { text: qsTr("Manual") }
                    }
                }

                Component.onCompleted: {
                    var s = settings.appTheme(flatpak);

                    if (flatpak == settings.defaultApp()) {
                        themesw.checked = true;
                        themesw.visible = false;
                    } else {
                        if (s !== 0) themesw.checked = true;
                        else themesw.checked = false;
                    }

                    if (!themesw.checked)
                        s = settings.appTheme(settings.defaultApp());

                    if (s === 1) tsw.currentIndex = 0;
                    else if (s === 2) tsw.currentIndex = 1;
                    else if (s === 3) tsw.currentIndex = 2;
                    else if (s === -1) tsw.currentIndex = 3;
                }

                Connections {
                    target: dia
                    onAccepted: {
                        var s = 0;
                        if (themesw.checked) {
                            if (tsw.currentIndex === 0) s = 1;
                            else if (tsw.currentIndex === 1) s = 2;
                            else if (tsw.currentIndex === 2) s = 3;
                            else if (tsw.currentIndex === 3) s = -1;
                        }
                        settings.setAppTheme(flatpak, s);
                    }
                }
            }

            Column {
                // scaling switch
                spacing: Theme.paddingMedium
                width: alist.width

                TextSwitch {
                    id: scsw
                    text: qsTr("Override scaling factor")
                    description: qsTr("Usually, it is not needed to override scaling factor. " +
                                      "However, applications using QtWebEngine may require " +
                                      "overriding the factor")
                }

                Slider {
                    id: scval
                    enabled: scsw.checked
                    maximumValue: Math.round(settings.defaultDpi() / 96)
                    minimumValue: 1
                    stepSize: 1
                    valueText: value
                    width: parent.width
                }

                Component.onCompleted: {
                    var s = settings.appScaling(flatpak);
                    if (s < 1) {
                        scsw.checked = false;
                        scval.value = 1;
                    } else {
                        scsw.checked = true;
                        scval.value = Math.min(s, scval.maximumValue);
                    }
                }

                Connections {
                    target: dia
                    onAccepted: {
                        var s = 0;
                        if (scsw.checked)
                            s = scval.value;
                        settings.setAppScaling(flatpak, s);
                    }
                }
            }

            Column {
                // dpi switch
                spacing: Theme.paddingMedium
                width: alist.width

                TextSwitch {
                    id: dpisw
                    text: qsTr("Override DPI")
                    description: qsTr("DPI is detected by default. When overriding scaling " +
                                      "factor, new DPI will be calculated by reducing it " +
                                      "accordingly. If, for some reason, you need still to force " +
                                      "DPI, you could override it here")
                }

                Slider {
                    id: dpival
                    enabled: dpisw.checked
                    maximumValue: settings.defaultDpi()
                    minimumValue: 50
                    stepSize: 1
                    valueText: value
                    width: parent.width
                }

                Component.onCompleted: {
                    var s = settings.appDpi(flatpak);
                    if (s < 1) {
                        dpisw.checked = false;
                        dpival.value = Math.round(settings.defaultDpi() /
                                                  Math.max(1,settings.appScaling(flatpak)));
                    } else {
                        dpisw.checked = true;
                        dpival.value = Math.min(s, dpival.maximumValue);
                    }
                }

                Connections {
                    target: dia
                    onAccepted: {
                        var s = 0;
                        if (dpisw.checked)
                            s = dpival.value;
                        settings.setAppDpi(flatpak, s);
                    }
                }
            }

            Column {
                // follow keyboard switch
                spacing: Theme.paddingMedium
                width: alist.width

                TextSwitch {
                    id: keyoversw
                    text: qsTr("Override keyboard handling")
                    description: qsTr("Override default keyboard handling.")
                }

                TextSwitch {
                    id: keysw
                    enabled: keyoversw.checked
                    text: qsTr("Reduce window when keyboard is shown")
                    description: qsTr("When enabled, surface showing the application is reduced to ensure that the keyboard does not " +
                                      "cover the application parts. This is sometimes needed in some of the applications. However, it may " +
                                      "cause temporary distortion in the shown window due to rescaling of the window before the application " +
                                      "catches up and redraws the window.")
                }

                Component.onCompleted: {
                    var s = settings.appFollowKeyboard(flatpak);

                    if (flatpak == settings.defaultApp()) {
                        keyoversw.checked = true;
                        keyoversw.visible = false;
                        if (s < 1)
                            keysw.checked = false;
                        else
                            keysw.checked = true;
                        return;
                    }

                    if (s < 0) {
                        keyoversw.checked = false;
                        keysw.checked = (settings.appFollowKeyboard(settings.defaultApp()) > 0);
                    } else if (s == 0) {
                        keyoversw.checked = true;
                        keysw.checked = false;
                    } else {
                        keyoversw.checked = true;
                        keysw.checked = true;
                    }
                }

                Connections {
                    target: dia
                    onAccepted: {
                        var s = 0;
                        if (!keyoversw.checked)
                            s = -1;
                        else if (keysw.checked)
                            s = 1;
                        settings.setAppFollowKeyboard(flatpak, s);
                    }
                }
            }

            Repeater {
                id: env
                delegate: ListItem {
                    id: item
                    contentHeight: e.height
                    visible: !removed
                    width: alist.width

                    property bool removed: false

                    Column {
                        id: e
                        spacing: Theme.paddingMedium
                        width: parent.width

                        SectionHeader {
                            text: qsTr("Environment variable")
                        }

                        TextField {
                            id: name
                            label: qsTr("Name")
                            placeholderText: label
                            text: model.key
                            width: parent.width
                            errorHighlight: !focus && !text
                            EnterKey.iconSource: "image://theme/icon-m-enter-next"
                            EnterKey.onClicked: {
                                if (!text) {
                                    return
                                }

                                value.forceActiveFocus()
                            }

                            Component.onCompleted: {
                                forceActiveFocus()
                            }
                        }

                        TextField {
                            id: value
                            label: qsTr("Value")
                            placeholderText: label
                            text: model.value
                            width: parent.width
                            errorHighlight: !focus && !text
                            EnterKey.iconSource: name.errorHighlight ? "image://theme/icon-m-enter-next"
                                                                     : "image://theme/icon-m-enter-accept"
                            EnterKey.onClicked: {
                                if (!text) {
                                    return
                                }

                                if (name.errorHighlight) {
                                    name.forceActiveFocus()
                                } else {
                                    value.focus = false
                                }
                            }
                        }

                        Button {
                            anchors.right: parent.right
                            anchors.rightMargin: Theme.horizontalPageMargin
                            preferredWidth: Theme.buttonWidthMedium
                            text: qsTr("Delete")
                            onClicked: item.removed = true
                        }

                        Space {}

                        Connections {
                            target: dia
                            onAccepted: {
                                if (item.removed) {
                                    settings.rmAppEnvVar(dia.flatpak, model.key);
                                    return;
                                }
                                var nkey = name.text;
                                var nvalue = value.text;
                                if (nkey !== model.key)
                                    settings.rmAppEnvVar(dia.flatpak, model.key);
                                if (nkey && (nkey !== model.key || nvalue !== model.value))
                                    settings.setAppEnvVar(dia.flatpak, nkey, nvalue);
                            }
                        }
                    }
                }

                model: ListModel {}
            }

            Space {}

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                preferredWidth: Theme.buttonWidthLarge
                text: qsTr("Add new variable")
                onClicked: {
                    env.model.append({"key": "", "value": ""});
                }
            }
        }

        VerticalScrollDecorator { flickable: alist }
    }

    Component.onCompleted: {
        var s = JSON.parse(settings.appEnvJson(flatpak));
        env.model.clear()
        for (var key in s)
            env.model.append({
                                 "key": key,
                                 "value": s[key]
                             });
    }
}

