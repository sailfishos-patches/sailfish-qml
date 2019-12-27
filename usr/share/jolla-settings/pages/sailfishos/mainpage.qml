import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Vault 1.0
import Sailfish.Policy 1.0
import org.nemomobile.configuration 1.0
import org.nemomobile.systemsettings 1.0
import com.jolla.settings.sailfishos 1.0
import com.jolla.settings.system 1.0 as MdmBanner
import Nemo.Ssu 1.1

Page {
    id: page

    readonly property bool pageActive: Qt.application.active && page.status === PageStatus.Active
    property alias storeIf: storeIfItem
    property var btrfsBalancer: null
    property bool downloadPending
    property int contentMargin: isPortrait ? Theme.horizontalPageMargin : Theme.paddingSmall

    function qsTrIdStrings() {
        //: The settings item label shown in settings main page
        //% "Sailfish OS updates"
        QT_TRID_NOOP("settings_sailfishos-sailfishos")

        //: Abbreviated form of settings_sailfishos-sailfishos
        //% "OS updates"
        QT_TRID_NOOP("settings_sailfishos-sailfishos_short")
    }

    function _showBackupPage() {
        var obj = pageStack.animatorPush(Qt.resolvedUrl("UpgradeBackupDialog.qml"), {"storagePicker": upgradeDetails.backupStoragePicker})
        obj.pageCompleted.connect(function(backupPage) {
            backupPage.continueOSUpdate.connect(storeIf.downloadUpdate)
        })
    }

    onPageActiveChanged: if (pageActive) storeIf.calculateDiskSpaceRequirements()

    Component.onCompleted: {
        if (hasBtrfs) {
            btrfsBalancer = Qt.createQmlObject(
                        "import com.jolla.settings.sailfishos 1.0;" +
                        "BtrfsBalancer { }",
                        page)
        }
    }

    StoreInterface {
        id: storeIfItem

        // make some shortcuts for cleaner code
        readonly property bool pending: updateStatus === StoreInterface.Unknown
                                        || (btrfsBalancer && btrfsBalancer.pending)

        readonly property bool haveUpgrade: updateStatus === StoreInterface.UpdateAvailable
                                            && updateProgress === 0
        readonly property bool haveDetails: updateStatus === StoreInterface.UpdateAvailable
                                            || updateStatus === StoreInterface.PreparingForUpdate
        readonly property bool downloading: updateProgress > 0 && updateProgress < 100
        readonly property bool downloaded: updateProgress === 100
        readonly property bool ssuRndModeRequiresRegistration: ssu.deviceMode & Ssu.RndMode && !ssu.registered
        readonly property bool ssuCbetaRequiresRegistration: ssu.domain === "cbeta" && !ssu.registered
        readonly property bool ssuDomainRequiresRegistration: ssu.domain !== "sales" && !ssu.registered
        readonly property bool ssuRequiresRegistration: ssuRndModeRequiresRegistration || ssuDomainRequiresRegistration
        readonly property bool accountsOk: storeIf.accountStatus === StoreInterface.AccountAvailable && !ssuRequiresRegistration
        readonly property bool diskOk: downloaded ? sufficientSpaceForInstall : sufficientSpaceForDownload
        readonly property real requiredDisk: downloaded ? osInstallSize : osDownloadSize
        readonly property real availableDisk: downloaded ? availableSpaceForInstall : availableSpaceForDownload

        readonly property bool mayDownload: AccessPolicy.osUpdatesEnabled && haveUpgrade && diskOk && sufficientBatteryForDownload
        readonly property bool mayInstall: AccessPolicy.osUpdatesEnabled && downloaded && diskOk && sufficientBatteryForInstall

        readonly property bool balancingRequired: haveUpgrade && btrfsBalancer && btrfsBalancer.required

        onRequiredDiskChanged: {
            if (downloadPending && sufficientSpaceForDownload) {
                if (upgradeDetails.backupEnabled) {
                    page._showBackupPage()
                } else {
                    storeIf.downloadUpdate()
                }
            }
            downloadPending = false
        }

        onBalancingRequiredChanged: {
            if (btrfsBalancer) {
                balancingUiLoader.source = Qt.resolvedUrl("BalancingUi.qml")
            }
        }
    }

    Ssu { id: ssu }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: content.height
        Column {
            id: content
            enabled: AccessPolicy.osUpdatesEnabled

            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(Screen.width, Screen.height)

            UpgradeHeader {
                charging: storeIf.batteryChargerConnected
            }

            MdmBanner.DisabledByMdmBanner {
                active: !content.enabled
            }

            Item { width: 1; height: Theme.paddingLarge }

            UpgradePlaceholder {
                horizontalMargin: contentMargin
                visible: !storeIf.accountsOk
            }

            Loader {
                id: balancingUiLoader
                visible: storeIf.accountsOk && storeIf.balancingRequired && !storeIf.pending
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: contentMargin
                }
            }

            UpgradeDetails {
                id: upgradeDetails
                horizontalMargin: contentMargin
                visible: storeIf.accountsOk && !storeIf.balancingRequired && !storeIf.pending
            }

            UpgradeSettings {
                horizontalMargin: contentMargin
                visible: upgradeDetails.visible
            }
        }

        PullDownMenu {
            id: pulleyMenu

            busy: storeIf.updateStatus === StoreInterface.Checking ||
                  storeIf.updateStatus === StoreInterface.WaitingForConnection
            visible: AccessPolicy.osUpdatesEnabled
                     && storeIf.accountsOk
                     && !storeIf.downloading
                     && !storeIf.balancingRequired

            MenuItem {
                visible: storeIf.updateStatus === StoreInterface.UpToDate
                         || storeIf.haveUpgrade || !storeIf.diskOk
                //: Check for system update menu item
                //% "Check for update"
                text: qsTrId("settings_sailfishos-me-check_system_update")
                onDelayedClick: {
                    // Hack: If already downloaded but we do not have valid os installation
                    // size, refresh update size. Os install size will be invalid
                    // when trying to download and install so that both partitions are full.
                    if (storeIf.downloaded && !storeIf.validOsInstallSize) {
                        storeIf.getUpdateSize()
                    }
                    storeIf.checkForUpdate()
                }
            }

            MenuItem {
                visible: storeIf.updateStatus !== StoreInterface.UpToDate
                enabled: storeIf.mayDownload || storeIf.mayInstall
                text: {
                    if (storeIf.haveUpgrade) {
                        //: Download system update menu item
                        //% "Download"
                        qsTrId("settings_sailfishos-me-download_system_update")
                    } else if (storeIf.downloading) {
                        //: Downloading system update menu item (disabled)
                        //% "Downloading"
                        qsTrId("settings_sailfishos-me-downloading_system_update")
                    } else if (storeIf.downloaded) {
                        //: Install system update menu item
                        //% "Install"
                        qsTrId("settings_sailfishos-me-install_system_update")
                    } else if (storeIf.updateStatus === StoreInterface.WaitingForConnection) {
                        //: Waiting for connection menu item (disabled)
                        //% "Waiting for connection"
                        qsTrId("settings_sailfishos-me-waiting_for_connection")
                    } else if (storeIf.updateStatus === StoreInterface.PreparingForUpdate) {
                        //: Preparing for update menu item (disabled)
                        //% "Preparing for update"
                        qsTrId("settings_sailfishos-me-preparing_for_update")
                    } else {
                        //: Checking for updates menu item (disabled)
                        //% "Checking for updates"
                        qsTrId("settings_sailfishos-me-checking")
                    }
                }

                onClicked: {
                    if (storeIf.haveUpgrade) {
                        if (storeIf.requiredDisk === -1) {
                            // This might happen if the background size check failed for some
                            // reason (e.g. out of network situation).
                            downloadPending = true
                            storeIf.getUpdateSize()
                        } else {
                            if (upgradeDetails.backupEnabled) {
                                page._showBackupPage()
                            } else {
                                storeIf.downloadUpdate()
                            }
                        }
                    } else if (storeIf.mayInstall) {
                        storeIf.installDownloadedUpdate()
                    }
                }
            }
        }
    }

    BusyIndicator {
        anchors.centerIn: parent
        running: storeIf.accountsOk && storeIf.pending
        size: BusyIndicatorSize.Large
    }
}
