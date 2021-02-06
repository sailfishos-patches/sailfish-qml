/*
 * Copyright (C) 2015 - 2016 Jolla Ltd.
 * Copyright (C) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.configuration 1.0
import com.jolla.settings 1.0
import com.jolla.notes.settings.translations 1.0

ApplicationSettings {
    ComboBox {
        id: transferFormatCombo
        //% "Sharing format"
        label: qsTrId("settings_notes-he-sharing_format")
        currentIndex: transferAsVNoteConfig.value == false ? 0 : 1
        onCurrentIndexChanged: transferAsVNoteConfig.value = currentIndex == 0 ? false : true
        menu: ContextMenu {
            id: transferFormatComboMenu
            MenuItem {
                id: transferAsPTextMenu
                //: Whether to transfer notes as plain text files
                //% "Plain-text"
                text: qsTrId("settings_notes-la-plain-text")
            }
            MenuItem {
                id: transferAsVNoteMenu
                //: Whether to transfer notes as vNote files
                //% "vNote"
                text: qsTrId("settings_notes-la-vnote")
            }
        }
    }

    Label {
        id: vnoteWarningLabel
        anchors.left: transferFormatCombo.left
        anchors.leftMargin: transferFormatCombo.labelMargin
        anchors.right: parent.right
        anchors.rightMargin: Theme.horizontalPageMargin
        visible: !transferFormatComboMenu._open && transferFormatCombo.currentIndex == 1
        color: Theme.secondaryHighlightColor
        font.pixelSize: Theme.fontSizeExtraSmall
        wrapMode: Text.Wrap
        opacity: (!transferFormatComboMenu._open && transferFormatCombo.currentIndex == 1) ? 1.0 : 0.0
        Behavior on opacity { FadeAnimation {} }
        height: visible ? implicitHeight : 0
        Behavior on height { NumberAnimation {} }
        //: Description informing the user of the disadvantes of using vNote format for sharing
        //% "Notes sent in vNote format may not be readable by the recipient"
        text: qsTrId("settings_notes-la-vnote_description")
    }

    ConfigurationValue {
       id: transferAsVNoteConfig
       key: "/apps/jolla-notes/settings/transferAsVNote"
       defaultValue: false
    }
}
