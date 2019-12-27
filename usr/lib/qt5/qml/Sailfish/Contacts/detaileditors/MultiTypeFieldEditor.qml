import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Contacts 1.0
import org.nemomobile.contacts 1.0

BaseEditor {
    id: root

    property string propertyAccessor
    property string valueField

    property var allowedTypes
    property var allowedSubTypes
    property bool subTypesExclusive

    property bool prepopulate
    property bool canChangeLabelType: true
    property bool canChangeFieldType: true
    property DetailSubTypeModel detailSubTypeModel: DetailSubTypeModel { subTypesExclusive: root.subTypesExclusive }

    function populateFieldEditor() {
        detailModel.reload(contact[propertyAccessor])
        detailSubTypeModel.reload(allowedTypes, allowedSubTypes)

        // Add an empty field to act as the 'Add new x' button
        addEmptyField()

        if (prepopulate && detailEditors.count === 1) {
            // Set the first field to input mode.
            detailEditors.itemAt(detailEditors.count - 1).buttonMode = false
        }
    }

    function aboutToSave() {
        detailModel.copyMultiTypeDetailChanges(contact, propertyAccessor)
    }

    function setDetailLabel(index, label) {
        var detail = detailModel.get(index)
        var nameForDetailType = ContactsUtil.getNameForDetailSubType(detail.type, detail.subType, undefined, true)
        detailModel.set(index, {
            "label": label,
            "name": nameForDetailType
        })
        detailModel.userModified = true
    }

    function setDetailType(index, type, subType) {
        var detail = detailModel.get(index)
        var nameForDetailType = ContactsUtil.getNameForDetailSubType(type, subType, undefined, true)
        detailModel.set(index, {
            "type": type,
            "subType": subType,
            "name": nameForDetailType
        })
        detailModel.userModified = true
    }

    function addEmptyField() {
        resetField(detailModel.count)
    }

    function resetField(detailIndex) {
        var properties = {
            "type": detailSubTypeModel.defaultType,
            "subType": detailSubTypeModel.defaultSubType,
            "label": Person.NoLabel,
            "name": ContactsUtil.getNameForDetailSubType(detailSubTypeModel.defaultType, detailSubTypeModel.defaultSubType, undefined, true),
            "value": root.detailModel.emptyValue,
            "sourceIndex": -1
        }
        if (detailIndex >= detailModel.count) {
            detailModel.append(properties)
        } else if (detailIndex >= 0) {
            detailModel.set(detailIndex, properties)
            detailModel.userModified = true
        } else {
            console.warn("Invalid detailIndex:", detailIndex)
        }
    }

    function _canRemoveEditorField() {
        if (!prepopulate || detailEditors.count > 2) {
            return true
        }

        // If prepopulate=true, always show at least one field in input mode, so don't allow
        // removal if removing this field means only the button-mode field is left.
        return detailEditors.count > 1 && !detailEditors.itemAt(detailEditors.count - 1).buttonMode
    }

    detailModel: MultiTypeDetailModel {
        valueField: root.valueField
        subTypesExclusive: root.subTypesExclusive
    }

    fieldDelegate: EditorFieldDelegate {
        id: editorField

        property int delegateIndex: model.index

        width: parent.width
        icon.source: root.fieldAdditionIcon
        showIconWhenEditing: model.index === 0
        inputMethodHints: root.inputMethodHints
        canRemove: root._canRemoveEditorField()

        detailSubTypeModel: root.canChangeFieldType ? root.detailSubTypeModel : null
        showDetailLabelCombo: root.canChangeLabelType
        editor: root

        onModified: {
            var wasEmpty = model.value.length === 0
            var isEmpty = value.length === 0
            root.detailModel.setProperty(model.index, "value", value)

            var lastItem = detailEditors.itemAt(root.detailModel.count - 1)
            if (wasEmpty && !isEmpty) {
                if (!lastItem.buttonMode) {
                    root.addEmptyField()
                }
            } else if (!wasEmpty && isEmpty) {
                if (lastItem.buttonMode) {
                    root.animateAndRemove(root.detailModel.count - 1, lastItem)
                }
            }
        }

        onRemoveClicked: {
            root.detailModel.setProperty(model.index, "value", "")
            if (!root.animateAndRemove(model.index, editorField)) {
                editorField.buttonMode = true
            }
        }

        onDetailSubTypeModified: root.setDetailType(model.index, type, subType)
        onDetailLabelModified: root.setDetailLabel(model.index, label)
    }
}
