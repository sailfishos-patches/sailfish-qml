/*
 * Copyright (c) 2012 - 2019 Jolla Ltd.
 * Copyright (c) 2019 Open Mobile Platform LLC.
 *
 * License: Proprietary
*/

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0
import Sailfish.Contacts 1.0
import org.nemomobile.contacts 1.0

BaseEditor {
    id: root

    property NicknameDetailModel nicknameModel

    // Each field in the InfoEditor is shown elsewhere in another editor instead if the field
    // already has a value when the editor page is initially shown. The InfoEditor provides for
    // adding/editing these fields if they were not already present when the editor was loaded.
    readonly property var _fields: [
        { "type": Person.TitleType, "propertyName": "title", "autoFillField": ContactDetailSuggestions.OrganizationTitle },
        { "type": Person.DepartmentType, "propertyName": "department", "autoFillField": ContactDetailSuggestions.OrganizationDepartment },
        { "type": Person.RoleType, "propertyName": "role", "autoFillField": ContactDetailSuggestions.OrganizationRole },
        { "type": Person.MiddleNameType, "propertyName": "middleName", "autoFillField": ContactDetailSuggestions.None }
    ]

    function populateFieldEditor() {
        detailModel.clear()
        addableTypesModel.clear()

        // Fill model of detail types that can be added by the user.
        for (var i = 0; i < root._fields.length; ++i) {
            var detail = root._fields[i]
            var value = contact[detail.propertyName]
            var properties = {
                "type": detail.type,
                "name": ContactsUtil.getNameForDetailType(detail.type),
                "propertyName": detail.propertyName,
                "autoFillField": detail.autoFillField,
                "canAdd": value.length === 0
            }
            addableTypesModel.append(properties)
        }

        addableTypesModel.append({
            "type": Person.NicknameType,
            "name": ContactsUtil.getNameForDetailType(Person.NicknameType),
            "propertyName": "",
            "canAdd": true
        })

        // Add an empty field to act as the 'add new x' button
        _addEmptyInfoDetailField()
    }

    function aboutToSave() {
        // Copy nickname additions to nicknameModel
        for (var i = 0; i < detailModel.count; ++i) {
            var detail = detailModel.get(i)
            if (detail.type === Person.NicknameType) {
                nicknameModel.append(detail)
                nicknameModel.userModified = true
            }
        }

        // Ignore nickname changes, as those are handled in ContactDetailDialog.
        detailModel.copySingleTypeDetailChanges(contact, Person.NicknameType)
    }

    function _initField(modelIndex, type, propertyName, autoFillField) {
        var delegateItem = detailEditors.itemAt(modelIndex)
        if (!delegateItem) {
            return
        }

        detailModel.set(modelIndex, {
            "type": type,
            "name": ContactsUtil.getNameForDetailType(type),
            "propertyName": propertyName,
            "autoFillField": autoFillField
        })
        delegateItem.buttonMode = false
        delegateItem.forceActiveFocus()

        if (type !== Person.NicknameType) {
            // Aside from nickname, only one entry for each field type is allowed, so remove this
            // from the 'add' options.
            for (var i = 0; i < addableTypesModel.count; i++) {
                if (addableTypesModel.get(i).type === type) {
                    addableTypesModel.setProperty(i, "canAdd", false)
                    break
                }
            }
        }
    }

    function _addEmptyInfoDetailField() {
        // Add empty field with property set that is superset of properties required for both
        // single-type (i.e. non-nickname) and multi-type (i.e. nickname) values.
        detailModel.append({
            "type": Person.NoType,
            "subType": Person.NoSubType,
            "label": Person.NoLabel,
            "name": "",
            "propertyName": "",
            "autoFillField": ContactDetailSuggestions.None,
            "value": "",
            "sourceIndex": -1
        })
    }

    //: Add miscellaneous detail (e.g. middle name, company department, etc.) for this contact
    //% "Add detail"
    fieldAdditionText: qsTrId("contacts-bt-contact_add_detail")
    fieldAdditionIcon: "image://theme/icon-m-down"

    fieldDelegate: ListItem {
        id: infoDelegate

        property int delegateIndex: model.index
        property alias buttonMode: editorField.buttonMode

        contentHeight: editorField.height
        menu: editorField.buttonMode ? addInfoMenuComponent : null

        EditorFieldDelegate {
            id: editorField

            icon.source: editorField.buttonMode ? root.fieldAdditionIcon : ""
            canRemove: true
            buttonMode: true
            exitButtonModeWhenClicked: false
            editor: root
            suggestionField: model.autoFillField

            onModified: {
                var wasEmpty = model.value.length === 0
                root.detailModel.setProperty(model.index, "value", value)

                if (wasEmpty && value.length > 0 && model.index === root.detailModel.count - 1
                        && addableTypesModel.count > 0) {
                    // Add an empty field to act as the 'add new x' button
                    root._addEmptyInfoDetailField()
                }

                root.hasContent = value.length > 0 || root.testHasContent()
            }

            onRemoveClicked: {
                var detailType = model.type
                root.detailModel.setProperty(model.index, "value", "")
                if (!root.animateAndRemove(model.index, infoDelegate)) {
                    editorField.buttonMode = true
                }

                // Allow this type to be added again
                if (detailType !== Person.NicknameType) {
                    for (var i = 0; i < root._fields.length; ++i) {
                        var detail = root._fields[i]
                        if (detail.type === detailType) {
                            addableTypesModel.setProperty(i, "canAdd", true)
                            break
                        }
                    }
                }
            }

            onClickedInButtonMode: infoDelegate.openMenu()
        }

        Component {
            id: addInfoMenuComponent

            ContextMenu {
                Repeater {
                    model: addableTypesModel

                    MenuItem {
                        text: model.name
                        visible: model.canAdd

                        onDelayedClick: {
                            var data = addableTypesModel.get(model.index)
                            root._initField(infoDelegate.delegateIndex, data.type, data.propertyName, data.autoFillField)

                            // Add an empty field to act as the 'add new x' button
                            root._addEmptyInfoDetailField()
                        }
                    }
                }
            }
        }
    }

    ListModel {
        id: addableTypesModel
    }
}
