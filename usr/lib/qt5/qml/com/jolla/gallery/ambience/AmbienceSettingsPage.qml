/*
 * Copyright (c) 2013 - 2020 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
*/

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Ambience 1.0

Page {
    id: root

    property alias contentId: view.contentId
    property alias ambience: view.ambience
    readonly property bool wasRemoved: _removed || removeRemorse.visible
    property bool _removed

    // Save only when user leaves the app or goes back to the previous page
    onStatusChanged: {
        if (status === PageStatus.Deactivating && !view.wasRemoved) {
            view.ambience.commitChanges()
        } else if (status === PageStatus.Inactive) {
            view.contentY = 0
        }
    }
    allowedOrientations: Orientation.All

    Wallpaper {
        width: parent.width
        height: Math.max(0, -view.contentY +  view.backgroundHeight)
        sourceItem: view.applicationWallpaper
        palette.colorScheme: ambience.colorScheme
    }

    AmbienceSettingsView {
        id: view

        width: root.width
        height: root.height

        PullDownMenu {

            palette {
                colorScheme: ambience.colorScheme
                highlightColor: ambience.highlightColor
            }

            MenuItem {
                enabled: Ambience.source != ambience.url

                //: Remove ambience from the ambience list
                //% "Remove ambience"
                text: qsTrId("jolla-gallery-ambience-me-remove_ambience")
                onClicked: {
                    //: Remorse popup text for ambience deletion
                    //% "Deleting Ambience"
                    removeRemorse.execute(qsTrId("jolla-gallery-ambience-delete-ambience"),
                                          function() {
                                              root._removed = true
                                              ambience.remove()
                                              pageStack.pop()
                                          })
                }
            }
            MenuItem {
                //: Restores an ambience's original settings
                //% "Reset to defaults"
                text: qsTrId("jolla-gallery-ambience-me-reset_to_defaults")
                onClicked: {
                    ambience.reset()
                }
            }
            MenuItem {
                enabled: Ambience.source != ambience.url

                //: Active the ambience
                //% "Set Ambience"
                text: qsTrId("jolla-gallery-ambience-me-set_ambience")
                onClicked: {
                    ambience.save()
                    Ambience.source = ambience.url
                }
            }
        }
    }

    RemorsePopup { id: removeRemorse }
}
