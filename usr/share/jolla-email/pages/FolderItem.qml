/*
 * Copyright (c) 2013 – 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Email 0.1
import "utils.js" as Utils

ListItem {
    id: folderItem

    property bool enableFolderActions
    property bool showUnreadCount
    property string folderDisplayName: (typeof(isRoot) === 'undefined' || !isRoot)
                                       ? Utils.standardFolderName(folderType, folderName)
                                       : //: No parent folder
                                         //% "None"
                                         qsTrId("jolla-email-la-none_folder")
    property bool isCurrentItem

    opacity: enabled ? 1 : (isCurrentItem ? Theme.opacityHigh : Theme.opacityLow)
    contentHeight: Screen.sizeCategory >= Screen.Large ? Theme.itemSizeMedium : Theme.itemSizeSmall

    Label {
        anchors {
            left: parent.left
            leftMargin: Theme.horizontalPageMargin + Theme.paddingLarge * folderNestingLevel
            right: folderItemUnreadCount.left
            rightMargin: Theme.paddingMedium
            verticalCenter: parent.verticalCenter
        }
        text: folderDisplayName
        font.pixelSize: Theme.fontSizeMedium
        color: (highlighted || isCurrentItem)
               ? Theme.highlightColor
               : Theme.primaryColor
        truncationMode: TruncationMode.Fade
    }

    Label {
        id: folderItemUnreadCount
        visible: folderUnreadCount && showUnreadCount
        anchors {
            right: parent.right
            rightMargin: Theme.horizontalPageMargin
            verticalCenter: parent.verticalCenter
        }
        text: folderUnreadCount
        font.pixelSize: Theme.fontSizeLarge
        color: Theme.highlightColor
    }
}
