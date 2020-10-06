/*
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */
import QtQuick 2.6
import Sailfish.Silica 1.0
import com.jolla.settings.accounts 1.0

Column {
    id: root

    property alias webdavPath: webdavPathField.text
    property alias addressbookPath: addressbookPathField.text
    property alias calendarPath: calendarPathField.text
    property alias imagesPath: imagesPathField.text
    property alias backupsPath: backupsPathField.text

    property string calendarServiceName
    property string calendarServerAddress
    readonly property bool calendarPathModified: _originalCalendarPath !== calendarPath

    property string _originalCalendarPath

    function _textFieldConfig(service) {
        if (service.serviceType === "carddav") {
            return { "field": addressbookPathField, "settingsKey": "addressbook_path" }
        } else if (service.serviceType === "caldav") {
            return { "field": calendarPathField, "settingsKey": "calendar_path" }
        } else if (service.name.search('-images$') >= 0) {
            return { "field": imagesPathField, "settingsKey": "images_path" }
        } else if (service.serviceType === "storage") {
            return { "field": backupsPathField, "settingsKey": "backups_path" }
        }
        return undefined
    }

    function setServiceFieldEnabled(service, enable) {
        var fieldConfig = _textFieldConfig(service)
        if (fieldConfig) {
            if (enable) {
                fieldConfig.field.visible = true
            }
            fieldConfig.field.enabled = enable
        }
    }

    function load(account, services) {
        for (var i = 0; i < services.length; ++i) {
            var service = services[i]
            var fieldConfig = _textFieldConfig(service)
            if (fieldConfig) {
                fieldConfig.field.visible = true
                if (!account) {
                    continue
                }

                // Load the saved text values
                var serviceSettings = account.configurationValues(service.name)
                var fieldText = serviceSettings[fieldConfig.settingsKey] || ""
                if (fieldText.length > 0) {
                    fieldConfig.field.text = fieldText
                }
                if (webdavPathField.text.length === 0) {
                    webdavPathField.text = serviceSettings["webdav_path"] || ""
                }

                if (fieldConfig.field === calendarPathField) {
                    _originalCalendarPath = calendarPathField.text
                    calendarServiceName = service.name
                    calendarServerAddress = serviceSettings["server_address"] || ""
                }
            }
        }
    }

    function saveChanges(account, services) {
        for (var i = 0; i < services.length; ++i) {
            var service = services[i]
            var fieldConfig = _textFieldConfig(service)
            if (fieldConfig) {
                account.setConfigurationValue(service.name, fieldConfig.settingsKey, fieldConfig.field.text)
                account.setConfigurationValue(service.name, "webdav_path", webdavPathField.text)
            }
        }
    }

    width: parent.width
    opacity: enabled ? 1 : Theme.opacityLow

    TextField {
        id: webdavPathField

        width: parent.width
        inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
        placeholderText: label
        //: The field where the user can enter their WebDAV path
        //% "WebDAV path"
        label: qsTrId("components_accounts-la-webdav_path")

        // If the user edits the text, break any bindings that automatically change it
        onTextChanged: if (activeFocus) text = text

        EnterKey.enabled: text || inputMethodComposing
        EnterKey.iconSource: "image://theme/icon-m-enter-next"
        EnterKey.onClicked: addressbookPathField.focus = true
    }

    TextField {
        id: addressbookPathField

        width: parent.width
        visible: false
        inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
        placeholderText: label
        //: The field where the user can enter their addressbook home set path.  It is optional and can normally be automatically discovered.
        //% "Address book path (optional)"
        label: qsTrId("components_accounts-la-optional_addressbook_path")

        // If the user edits the text, break any bindings that automatically change it
        onTextChanged: if (activeFocus) text = text

        EnterKey.enabled: text || inputMethodComposing
        EnterKey.iconSource: "image://theme/icon-m-enter-next"
        EnterKey.onClicked: calendarPathField.focus = true
    }

    TextField {
        id: calendarPathField

        width: parent.width
        visible: false
        inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
        placeholderText: label
        //: The field where the user can enter their calendar home set path.  It is optional and can normally be automatically discovered.
        //% "Calendar path (optional)"
        label: qsTrId("components_accounts-la-optional_calendar_path")

        // If the user edits the text, break any bindings that automatically change it
        onTextChanged: if (activeFocus) text = text

        EnterKey.enabled: text || inputMethodComposing
        EnterKey.iconSource: (imagesPathField.visible || backupsPathField.visible)
                             ? "image://theme/icon-m-enter-next"
                             : "image://theme/icon-m-enter-close"
        EnterKey.onClicked: {
            if (imagesPathField.visible) {
                imagesPathField.focus = true
            } else if (backupsPathField.visible) {
                backupsPathField.focus = true
            } else {
                parent.focus = true
            }
        }
    }

    TextField {
        id: imagesPathField

        width: parent.width
        visible: false
        //% "Images path"
        label: qsTrId("components_accounts-la-images_path")
        placeholderText: label

        // If the user edits the text, break any bindings that automatically change it
        onTextChanged: if (activeFocus) text = text

        EnterKey.iconSource: backupsPathField.visible
                             ? "image://theme/icon-m-enter-next"
                             : "image://theme/icon-m-enter-close"
        EnterKey.onClicked: (backupsPathField.visible ? backupsPathField : parent).focus = true
    }

    TextField {
        id: backupsPathField

        width: parent.width
        visible: false
        //% "Backups path"
        label: qsTrId("components_accounts-la-backups_path")
        placeholderText: label

        // If the user edits the text, break any bindings that automatically change it
        onTextChanged: if (activeFocus) text = text

        EnterKey.iconSource: "image://theme/icon-m-enter-close"
        EnterKey.onClicked: parent.focus = true
    }
}
