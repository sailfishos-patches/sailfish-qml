import QtQuick 2.0
import Sailfish.Silica 1.0
import org.pycage.jollastore 1.0
import Sailfish.Policy 1.0

Page {
    id: page

    property int gridColumns: {
        if (Screen.sizeCategory > Screen.Medium) {
            return isPortrait ? 2 : 3
        } else {
            return isPortrait ? 1 : 2
        }
    }
    property int gridItemWidth: Math.floor((width - 2 * appGridMargin - (gridColumns - 1) * appGridSpacing) / gridColumns)

    objectName: "InstalledPage"

    function sectionLabel(appSection) {
        if (appSection == ApplicationState.Updatable) {
            //: Update available section label
            //% "Update available"
            return qsTrId("jolla-store-li-updatable")
        } else if (appSection == ApplicationState.Installing) {
            //: Installing section label
            //% "Installing"
            return qsTrId("jolla-store-li-installing")
        } else {
            //: Installed section label
            //% "Up to date"
            return qsTrId("jolla-store-li-installed")
        }
    }

    AppActions {
        id: actions
    }

    ContentGridModel {
        id: installedGridModel

        sourceModel: installedModel
        columns: gridColumns
    }

    PolicyValue {
        id: installPolicy
        policyType: PolicyValue.ApplicationInstallationEnabled
    }

    SilicaListView {
        id: listView

        anchors.fill: parent
        model: installedGridModel.list

        header: PageHeader {
            width: listView.width
            //: Page header for the My apps page
            //% "My apps"
            title: qsTrId("jolla-store-he-installed_apps")
        }

        delegate: Row {
            x: appGridMargin
            // TODO: Should not add "spacing" for the last row of a section.
            height: Theme.itemSizeLarge + appGridSpacing
            spacing: appGridSpacing

            Repeater {
                model: modelData
                AppListItem {
                    menu: appState === ApplicationState.Installing ? null : contextMenuComponent
                    contentHeight: Theme.itemSizeLarge
                    width: gridItemWidth

                    title: model ? model.title : ""
                    icon: model ? model.icon : ""
                    appState: model ? model.appState : ApplicationState.Normal
                    progress: model ? model.progress : 100

                    function confirmUninstall() {
                        var uuid = model.uuid
                        var packageName = model.packageName

                        remorseAction(
                            //: Uninstall label for remorse item
                            //% "Uninstalling"
                            qsTrId("jolla-store-la-remorse_uninstalling"),
                            function() { actions.uninstall(uuid, packageName) })
                    }

                    function updateApplication() {
                        actions.update(model.uuid, model.packageName)
                    }

                    onClicked: {
                        navigationState.openApp(model.uuid, model.appState)
                    }

                    Binding {
                        target: parent
                        when: menuOpen
                        property: "height"
                        value: height + appGridSpacing
                    }

                    Component {
                        id: contextMenuComponent
                        ContextMenu {
                            MenuItem {
                                enabled: installPolicy.value
                                //: Uninstall menu item
                                //% "Uninstall"
                                text: qsTrId("jolla-store-me-uninstall")
                                onClicked: confirmUninstall()
                            }
                            MenuItem {
                                visible: appState === ApplicationState.Updatable
                                //: Update menu item
                                //% "Update"
                                text: qsTrId("jolla-store-me-update")
                                onClicked: updateApplication()
                            }
                        }
                    }
                }
            }
        }

        section.property: "modelData.appSection"
        section.delegate: SectionHeader {
            text: page.sectionLabel(section)
        }

        footer: Item {
            visible: jollaStore.isOnline
                     && installedModel.loading
                     && !busyIndicator.running
            height: visible ? Theme.itemSizeSmall : 0
            width: listView.width

            BusyIndicator {
                anchors.centerIn: parent
                running: parent.visible
                size: BusyIndicatorSize.Medium
            }
        }

        PullDownMenu {
            MenuItem {
                enabled: installedModel.updateCount > 0
                //: Update all menu item
                //% "Update all"
                text: qsTrId("jolla-store-me-update_all")
                onClicked: {
                    installedModel.updateAll()
                }
            }
        }

        PageBusyIndicator {
            id: busyIndicator
            running: jollaStore.connectionState === JollaStore.Connecting ||
                     (installedModel.loading && installedModel.count === 0)
        }

        ViewPlaceholder {
            enabled: !busyIndicator.running &&
                     installedModel.count === 0 &&
                     !pageStack.busy
            //: View placeholder when there are no installed applications
            //% "Nothing installed"
            text: qsTrId("jolla-store-li-nothing_installed")
        }

        VerticalScrollDecorator { }
    }
}
