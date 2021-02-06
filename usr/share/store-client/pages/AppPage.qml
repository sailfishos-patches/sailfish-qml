import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.TextLinking 1.0
import org.pycage.jollastore 1.0
import Sailfish.Policy 1.0

Page {
    id: page

    objectName: "AppPage"

    property alias application: appData.application
    property string packageVersion: appData.packageInstalled
                                    ? packageHandler.packageVersion(appData.packageName)
                                    : appData.version

    property int _contentWidth: Math.min(Screen.width, Screen.height)
    property int _contentMargin: page.isPortrait ? Theme.horizontalPageMargin : Theme.paddingSmall

    ApplicationData {
        id: appData
    }

    AppLauncher {
        id: launcher
        packageName: appData.state === ApplicationState.Installed
                     ? appData.packageName
                     : ""
    }

    PolicyValue {
        id: policy
        policyType: PolicyValue.ApplicationInstallationEnabled
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            visible: (uninstallMenuItem.canShow
                      || openMenuItem.canShow
                      || updateMenuItem.canShow
                      || installMenuItem.canShow)
                     && appData.packageName !== ""

            MenuItem {
                id: uninstallMenuItem
                readonly property bool canShow: policy.value && (appData.state === ApplicationState.Installed
                                                                 || appData.state === ApplicationState.Updatable)

                visible: canShow
                //: Uninstall menu item
                //% "Uninstall"
                text: qsTrId("jolla-store-me-uninstall")

                onClicked: {
                    var previousPage = pageStack.previousPage(page)
                    if (previousPage) {
                        pageStack.pop()
                    }

                    var packageName = appData.packageName
                    var handler = packageHandler
                    Remorse.popupAction(
                                previousPage || page,
                                //: Uninstall label for remorse item
                                //% "Uninstalling %1"
                                qsTrId("jolla-store-la-remorse_uninstalling_app").arg(appData.title), function() {
                                    handler.uninstall(packageName, false)
                                } )
                }
            }

            MenuItem {
                id: openMenuItem
                readonly property bool canShow: appData.state === ApplicationState.Installed && launcher.isExecutable

                visible: canShow
                //: Open menu item
                //% "Open"
                text: qsTrId("jolla-store-me-open")
                onDelayedClick: launcher.launchApplication()
            }

            MenuItem {
                id: updateMenuItem
                readonly property bool canShow: jollaStore.isOnline && appData.state === ApplicationState.Updatable

                visible: canShow
                //: Update menu item
                //% "Update"
                text: qsTrId("jolla-store-me-update")
                onDelayedClick: appData.update()
            }

            MenuItem {
                id: installMenuItem
                readonly property bool canShow: policy.value && jollaStore.isOnline
                                                && appData.state === ApplicationState.Normal

                visible: canShow
                //: Install menu item
                //% "Install"
                text: qsTrId("jolla-store-me-install")
                onDelayedClick: appData.install()
            }
        }

        Column {
            id: column

            anchors.horizontalCenter: parent.horizontalCenter
            width: _contentWidth

            AppPageHeader {
                app: appData
                horizontalMargin: _contentMargin
            }

            Item { width: 1; height: Theme.paddingMedium }

            PolicyBanner {
                active: !policy.value
                uninstall: appData.state === ApplicationState.Installed
                           || appData.state === ApplicationState.Updatable
            }

            AppPageStatusArea {
                app: appData
                horizontalMargin: _contentMargin
            }

            Item { width: 1; height: Theme.paddingMedium; visible: appData.inStore }

            AppPageDetails {
                app: appData
                horizontalMargin: _contentMargin
            }

            AppScreenshots {
                visible: appData.inStore && urls.length > 0
                urls: appData.screenshots
            }

            AppPageReviews {
                app: appData
                horizontalMargin: _contentMargin
            }

            AppPageAlsoBy {
                app: appData
                horizontalMargin: _contentMargin
                gridMargin: page.isPortrait ? appGridMargin : 0
            }

            Item { width: 1; height: Theme.paddingLarge }

        }

        VerticalScrollDecorator { }
    }
}
