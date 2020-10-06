/*
 * Copyright (c) 2019 Jolla Ltd.
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

    readonly property var _fields: [
        { "type": Person.CompanyType, "propertyName": "companyName", "persistent": true, "autoFillField": ContactDetailSuggestions.OrganizationName },
        { "type": Person.TitleType, "propertyName": "title", "persistent": false, "autoFillField": ContactDetailSuggestions.OrganizationTitle },
        { "type": Person.DepartmentType, "propertyName": "department", "persistent": false, "autoFillField": ContactDetailSuggestions.OrganizationDepartment },
        { "type": Person.RoleType, "propertyName": "role", "persistent": false, "autoFillField": ContactDetailSuggestions.OrganizationRole },
    ]

    function populateFieldEditor() {
        detailModel.clear()

        for (var i = 0; i < root._fields.length; i++) {
            var detail = root._fields[i]
            var value = contact[detail.propertyName]
            if (!detail.persistent && value.length === 0) {
                continue
            }

            detailModel.append({
                "type": detail.type,
                "name": ContactsUtil.getNameForDetailType(detail.type),
                "propertyName": detail.propertyName,
                "autoFillField": detail.autoFillField,
                "value": value
            })
        }
    }

    function aboutToSave() {
        detailModel.copySingleTypeDetailChanges(contact)
    }

    fieldDelegate: EditorFieldDelegate {
        editor: root
        icon.source: "image://theme/icon-m-company"

        suggestionField: model.autoFillField

        onModified: root.detailModel.setProperty(model.index, "value", value)
    }
}
