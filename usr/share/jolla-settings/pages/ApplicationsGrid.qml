/*
 * Copyright (c) 2015 - 2018 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0
import com.jolla.settings 1.0

Item {
    id: root
    property alias gridView: gridView
    property bool sectionHeaderVisible: true

    width: parent.width
    height: gridView.height

    function openSandboxed(name, treeItem, icon, filePath) {
        var page
        if (treeItem === undefined || treeItem.type !== "application") {
            if (treeItem !== undefined) {
                console.warn("Can not use settings type '%1' for sandboxed application".arg(treeItem.type))
                console.warn("Use 'application' instead and use ApplicationSettings as top-level item")
                console.warn("Showing only application permissions, please fix your application")
            }
            page = sandboxedSettings
        } else /* treeItem.type === "application" */ {
            // QML can't check that component is created from the right type so the check that it
            // is ApplicationSettings should have been already done when the package is installed
            page = treeItem.data()["params"]["source"]
        }
        pageStack.animatorPush(page, { "applicationName": name, "applicationIcon": icon, "_desktopFile": filePath })
    }

    function openSettings(name, treeItem, icon) {
        var objdata = treeItem.data()
        var entryPath = treeItem.location().join("/")

        if (treeItem.type === "page") {
            console.warn("Warning: Settings type 'page' is deprecated. Use 'application' instead and use ApplicationSettings for top-level item")
            // TODO: should pass properties in all places
            var properties = objdata["params"]["properties"] !== undefined
                    ? objdata["params"]["properties"]
                    : {}
            properties["applicationName"] = name
            properties["applicationIcon"] = icon
            pageStack.animatorPush(objdata["params"]["source"], properties)
        } else if (treeItem.type === "application") {
            pageStack.animatorPush(objdata["params"]["source"], { "applicationName": name, "applicationIcon": icon })
        } else {
            var pageParams = {
                "entryPath": entryPath,
                "depth": objdata["params"] !== undefined && objdata["params"]["depth"] > 0
                ? objdata["params"]["depth"] : 1
            }
            pageStack.animatorPush("SettingsPage.qml", pageParams)
        }
    }

    Component {
        id: sandboxedSettings
        ApplicationSettings { }
    }

    ApplicationsGridView {
        id: gridView

        height: (headerItem ? headerItem.height : 0) + cellHeight * Math.ceil(count/columnCount)
        interactive: false

        header: sectionHeaderVisible ? sectionHeader : null

        Component {
            id: sectionHeader
            SectionHeader {
                width: gridView.width + (root.width - gridView.width)/2 - Theme.horizontalPageMargin
                //% "Applications"
                text: qsTrId("settings-he-applications")
            }
        }

        delegate: Item {
            id: wrapper

            property int modelIndex: index

            width: appItem.width
            height: appItem.height

            LauncherGridItem {
                id: appItem

                property bool configurable: (model.section !== undefined)
                                            && ((model.section.count(1) > 0)
                                                || (model.section.type == "page")
                                                || (model.section.type == "application"))

                width: gridView.cellWidth
                height: gridView.cellHeight
                enabled: configurable || model.sandboxed
                icon: model.iconId
                text: model.name

                onClicked: {
                    if (model.sandboxed) {
                        root.openSandboxed(text, model.section, model.iconId, model.filePath)
                    } else if (configurable) {
                        root.openSettings(text, model.section, model.iconId)
                    }
                }
            }
        }
    }
}
