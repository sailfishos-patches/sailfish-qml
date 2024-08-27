/*
 * Copyright (c) 2013 – 2019 Jolla Ltd.
 * Copyright (c) 2019 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQml.Models 2.1

DelegateModel {
    property alias allItems: allItemsGroup
    property alias selectedItems: selectedItemsGroup
    property alias hiddenItems: hiddenItemsGroup

    function hideSelected() {
        if (selectedItemsGroup.count > 0) {
            selectedItemsGroup.setGroups(0, selectedItemsGroup.count, ["hidden", "all"])
        }
    }

    function selectAll() {
        if (allItems.count > 0) {
            allItems.addGroups(0, allItems.count, ["selected"])
        }
    }

    function clearSelected() {
        if (selectedItemsGroup.count > 0) {
            selectedItemsGroup.remove(0, selectedItemsGroup.count)
        }
    }

    function clearHidden() {
        if (hiddenItemsGroup.count > 0) {
            hiddenItemsGroup.setGroups(0, hiddenItemsGroup.count, ["items", "all"])
        }
    }

    function selectItem(index) {
        allItems.addGroups(index, 1, ["selected"])
    }

    function deselectItem(index) {
        allItems.removeGroups(index, 1, ["selected"])
    }

    groups: [
        DelegateModelGroup {
            id: allItemsGroup

            name: "all"
            includeByDefault: true
        },
        DelegateModelGroup {
            id: selectedItemsGroup

            name: "selected"
        },
        DelegateModelGroup {
            id: hiddenItemsGroup

            name: "hidden"
        }
    ]
}
