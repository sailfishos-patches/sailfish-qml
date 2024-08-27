/****************************************************************************************
** Copyright (c) 2021 Open Mobile Platform LLC.
** Copyright (c) 2023 Jolla Ltd.
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
import Sailfish.Silica.private 1.0 as SilicaPrivate
import Sailfish.Silica.Background 1.0
import Sailfish.Lipstick 1.0
import Sailfish.TransferEngine 1.0
import Sailfish.Share 1.0
import Nemo.DBus 2.0

SystemDialog {
    id: root

    property var shareActionConfiguration

    readonly property int _windowMargin: Theme.paddingMedium
    readonly property int _topWindowMargin: (orientation === Qt.PortraitOrientation
                                             || orientation === Qt.InvertedPortraitOrientation)
                                            ? Theme.itemSizeHuge
                                            : 0
    readonly property real _windowWidthInPortrait: Screen.width - _windowMargin*2
    readonly property real _windowWidthInLandscape: (Screen.height * 3/4) - _windowMargin*2

    contentHeight: content.height
    category: SystemDialogWindow.Alarm

    layoutItem.contentItem.x: {
        var screenWidth = (orientation === Qt.PortraitOrientation || orientation === Qt.InvertedPortraitOrientation)
                ? Screen.width
                : Screen.height
        return screenWidth/2 - layoutItem.contentItem.width/2
    }
    layoutItem.contentItem.y: layoutItem.height - layoutItem.contentItem.height - _windowMargin

    layoutItem.contentItem.width: (orientation === Qt.PortraitOrientation || orientation === Qt.InvertedPortraitOrientation)
                                  ? _windowWidthInPortrait
                                  : _windowWidthInLandscape
    layoutItem.contentItem.height: content.y + content.height

    backgroundRect: {
        switch (orientation) {
        case Qt.LandscapeOrientation:
            return Qt.rect(_windowMargin
                           + __silica_applicationwindow_instance.pageStack.panelSize,
                           Screen.height/2 - _windowWidthInLandscape/2,
                           layoutItem.contentItem.height,
                           _windowWidthInLandscape)
        case Qt.InvertedPortraitOrientation:
            return Qt.rect(_windowMargin,
                           _windowMargin
                           + __silica_applicationwindow_instance.pageStack.panelSize,
                           _windowWidthInPortrait,
                           layoutItem.contentItem.height)
        case Qt.InvertedLandscapeOrientation:
            return Qt.rect(width - layoutItem.contentItem.height - _windowMargin
                           - __silica_applicationwindow_instance.pageStack.panelSize,
                           Screen.height/2 - _windowWidthInLandscape/2,
                           layoutItem.contentItem.height,
                           _windowWidthInLandscape)
        case Qt.PortraitOrientation:
        default:
            return Qt.rect(Screen.width/2 - layoutItem.contentItem.width/2,
                           Screen.height - layoutItem.contentItem.height - _windowMargin
                           - __silica_applicationwindow_instance.pageStack.panelSize,
                           _windowWidthInPortrait,
                           layoutItem.contentItem.height)
        }
    }

    Component.onCompleted: {
        shareAction.loadConfiguration(root.shareActionConfiguration)
    }

    ShareAction {
        id: shareAction

        onDone: root.dismiss()
    }

    SailfishSharingMethodsModel {
        id: sharingMethodsModel

        mimeTypeFilter: shareAction.mimeType
        filterByMultipleFileSupport: shareAction.resources.length > 1
    }

    SilicaPrivate.RoundedWindowCorners {
       anchors.fill: parent
       radius: Theme.paddingLarge
    }

    SilicaFlickable {
        id: content

        width: parent.width
        height: {
            var screenHeight = (orientation === Qt.PortraitOrientation || orientation === Qt.InvertedPortraitOrientation
                                ? Screen.height
                                : Screen.width) - __silica_applicationwindow_instance.pageStack.panelSize
            return Math.min(screenHeight - _windowMargin*2 - _topWindowMargin, contentHeight)
        }

        contentHeight: {
            if (loadingIndicator.running || delayLoadingIndicator.running) {
                return loadingIndicator.y + loadingIndicator.height
            } else if (shareMethodsColumn.visible) {
                return shareMethodsColumn.y + shareMethodsColumn.height
            } else {
                return shareMethodLoader.y + shareMethodLoader.height
            }
        }
        clip: true

        Behavior on contentHeight {
            NumberAnimation { duration: 150 }
        }

        VerticalScrollDecorator {}

        SystemDialogHeader {
            id: dialogHeader

            title: shareAction.title.length
                   ? shareAction.title
                     //% "Share"
                   : qsTrId("sailfishshare-he-share")
            topPadding: Theme.paddingLarge

            IconButton {
                anchors {
                    verticalCenter: parent.verticalCenter
                    right: parent.right
                    rightMargin: Theme.paddingMedium
                }
                icon.source: "image://theme/icon-m-reset"
                onClicked: root.dismiss()
            }
        }

        Loader {
            id: shareMethodLoader

            anchors.top: dialogHeader.bottom
            width: parent.width
            height: status === Loader.Ready ? item.height : placeholder.height
            asynchronous: true

            visible: !loadingIndicator.running && !delayLoadingIndicator.running && !shareMethodsColumn.visible
            opacity: visible ? 1 : 0
            Behavior on opacity { FadeAnimator {} }

            onStatusChanged: {
                if (status === Loader.Error) {
                    console.warn("Unable to load share plugin file:", shareMethodLoader.source)
                }
            }

            Item {
                id: placeholder

                width: parent.width
                height: Math.max(shareMethodsColumn.height,
                                 Theme.itemSizeHuge * 2,
                                 Theme.paddingLarge*2 + errorLabel.height)

                BusyIndicator {
                    id: busyIndicator

                    anchors {
                        centerIn: parent
                        verticalCenterOffset: -Theme.paddingLarge
                    }
                    running: !sharingMethodsModel.ready
                             || shareMethodLoader.status === Loader.Loading
                    size: BusyIndicatorSize.Large
                }

                InfoLabel {
                    id: errorLabel

                    anchors.centerIn: busyIndicator
                    width: parent.width - Theme.horizontalPageMargin*2
                    visible: shareMethodLoader.status === Loader.Error
                             || (sharingMethodsModel.ready && sharingMethodsModel.count === 0)

                    text: shareMethodLoader.status === Loader.Error
                            //% "Unable to load sharing app"
                          ? qsTrId("sailfishshare-la-load_app_error")
                          : (sharingMethodsModel.filterByMultipleFileSupport
                               //: User is trying to share multiple files, but there are no apps that support this action
                               //% "No apps available for multi-file sharing"
                             ? qsTrId("sailfishshare-la-no_apps_available_for_multi_file_sharing")
                               //: User is trying to share a file, but there are no apps that support file sharing
                               //% "No apps available for file sharing"
                             : qsTrId("sailfishshare-la-no_apps_available_for_file_sharing"))
                }
            }
        }

        BusyIndicator {
            id: loadingIndicator

            anchors {
                top: dialogHeader.bottom
                horizontalCenter: parent.horizontalCenter
            }
            height: Theme.itemSizeLarge
            running: !delayLoadingIndicator.running
                     && !shareMethodsColumn.visible
                     && shareMethodLoader.status === Loader.Null
                     && !sharingMethodsModel.ready
        }

        Timer {
            id: delayLoadingIndicator

            interval: 100
            running: !shareMethodsColumn.visible
                     && shareMethodLoader.status === Loader.Null
        }

        Column {
            id: shareMethodsColumn

            anchors.top: dialogHeader.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            bottomPadding: Theme.paddingLarge
            width: parent.width

            visible: sharingMethodsModel.ready
                     && sharingMethodsModel.count > 0
                     && shareMethodLoader.status === Loader.Null
            opacity: visible ? 1 : 0
            Behavior on opacity { FadeAnimator {} }

            Repeater {
                model: sharingMethodsModel

                delegate: ShareMethodItem {
                    onClicked: {
                        shareAction.selectedTransferMethodInfo = sharingMethodsModel.get(model.index)
                        shareMethodLoader.setSource(shareUIPath,
                                                    { "shareAction": shareAction })
                        content.contentY = 0
                    }
                }
            }
        }

    }

    DBusInterface {
        id: settingsApp

        service: "com.jolla.settings"
        path: "/com/jolla/settings/ui"
        iface: "com.jolla.settings.ui"
    }
}
