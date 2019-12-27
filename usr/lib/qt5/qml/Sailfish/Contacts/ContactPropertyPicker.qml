import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.contacts 1.0

QtObject {
    id: root

    property var silicaListView
    property var contactDelegateItem
    property alias contact: propertyModel.contact
    property alias requiredProperty: propertyModel.requiredProperty
    property var propertySelectedCallback
    property bool closeOnSelection: true

    readonly property bool pickerPageActive: !!_activePickerPage && _activePickerPage.status === PageStatus.Active

    property var _activeContextMenu
    property var _activePickerPage

    function openMenu() {
        if (!silicaListView) {
            console.log("Error: cannot load property picker, list view not set!")
            return
        }
        if (!contactDelegateItem) {
            console.warn("Error: cannot load property picker, delegate item not set!")
            return
        }
        if (!contact) {
            console.warn("Error: cannot load property picker, contact not set!")
            return
        }
        if (requiredProperty === PeopleModel.NoPropertyRequired) {
            console.warn("Error: cannot load property picker, requiredProperty not set!")
            return
        }

        // If the list view has an active context menu, embed the property picker into that instead
        // of opening a new context menu.
        var contextMenu = silicaListView.__silica_contextmenu_instance && silicaListView.__silica_contextmenu_instance.active
                ? silicaListView.__silica_contextmenu_instance
                : null
        _activeContextMenu = contextMenu

        // Max menu items to show inline, as per Silica ComboBox.
        var maximumInlineItems = Screen.sizeCategory >= Screen.Large ? 6 : 5
        if (propertyModel.count > maximumInlineItems) {
            // There are too many items to show inline, so show them on a separate page.
            pageStack.animatorPush(_pickerPageComponent)
            closeMenu()
            return
        }

        if (propertyModel.count === 0) {
            _propertySelected({}, contextMenu)
        } else if (propertyModel.count === 1) {
            // There's only one selectable property, so select it immediately instead of
            // showing the picker.
            root._propertySelected(propertyModel.get(0), contextMenu)
        } else {
            // Open the property picker in the currently active context menu if found, or
            // otherwise open a new context menu.
            if (contextMenu) {
                _propertyPickerItemComponent.createObject(contextMenu, {"menu": contextMenu})
            } else {
                contactDelegateItem.menu = _propertyMenuComponent
                contactDelegateItem.openMenu({})
            }
        }
    }

    function openPickerPageMenu(menu, menuProperties) {
        if (!pickerPageActive) {
            console.warn("Cannot open context menu, property picker page is not active!")
            return
        }
        _activePickerPage.openContextMenu(menu, menuProperties)
    }

    function closeMenu() {
        if (_activeContextMenu && _activeContextMenu.active) {
            _activeContextMenu.close()
            _activeContextMenu = null
        }
        if (_activePickerPage && _activePickerPage.status === PageStatus.Active) {
            pageStack.pop()
            _activePickerPage = null
        }
    }

    function _propertySelected(propertyData, contextMenu) {
        if (contactDelegateItem.selectionModel && contactDelegateItem.selectionModelIndex < 0) {
            contactDelegateItem.selectionModel.addContact(
                        contactDelegateItem.contactId, propertyData.property, propertyData.propertyType)
        }
        propertySelectedCallback(contact, propertyData, contextMenu, root)
        if (closeOnSelection) {
            closeMenu()
        }
    }

    property var _propertyModel: ContactPropertyModel {
        id: propertyModel
    }

    property var _propertyMenuComponent: Component {
        ContextMenu {
            id: contextMenu

            ContactPropertyPickerItem {
                id: propertyPicker

                menu: contextMenu
                propertyModel: root._propertyModel

                onPropertySelected: root._propertySelected(propertyData, contextMenu)
            }
        }
    }

    property var _propertyPickerItemComponent: Component {
        ContactPropertyPickerItem {
            id: propertyPickerItem

            propertyModel: root._propertyModel

            onPropertySelected: root._propertySelected(propertyData, menu)

            Connections {
                target: propertyPickerItem.menu
                onClosed: {
                    propertyPickerItem.destroy()
                }
            }
        }
    }

    property var _pickerPageComponent: Component {
        ContactPropertyPickerPage {
            id: pickerPage

            propertyModel: _propertyModel

            onPropertySelected: root._propertySelected(propertyData, null)

            onStatusChanged: {
                if (status === PageStatus.Inactive) {
                    root._activePickerPage = null
                }
            }

            Component.onCompleted: root._activePickerPage = pickerPage
        }
    }
}
