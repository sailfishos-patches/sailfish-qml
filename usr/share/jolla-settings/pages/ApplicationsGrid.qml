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

    function openSettings(name, treeItem) {
        var objdata = treeItem.data()
        var entryPath = treeItem.location().join("/")

        if (treeItem.type === "page") {
            // TODO: should pass properties in all places
            var properties = objdata["params"]["properties"] !== undefined
                    ? objdata["params"]["properties"]
                    : {}
            properties["applicationName"] = name
            pageStack.animatorPush(objdata["params"]["source"], properties)
        } else {
            var pageParams = {
                "entryPath": entryPath,
                "depth": objdata["params"] !== undefined && objdata["params"]["depth"] > 0
                ? objdata["params"]["depth"] : 1
            }
            pageStack.animatorPush("SettingsPage.qml", pageParams)
        }
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
                                                || (model.section.type == "page"))

                width: gridView.cellWidth
                height: gridView.cellHeight
                enabled: configurable
                icon: model.iconId
                text: model.name

                onClicked: {
                    if (configurable) {
                        root.openSettings(text, model.section)
                    }
                }
            }
        }
    }
}
