import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0
import org.pycage.jollastore 1.0
import Nemo.DBus 2.0
import Sailfish.Policy 1.0

SystemDialog {
    id: dialog

    property string _tohId
    property string _packageName
    property string _packageTitle
    //: Store client fetching TOH information from the store
    //% "Fetching TOH information"
    property string _descriptionText: qsTrId("jolla-store-la-fetching_ambience_information")

    property string _uuid
    property string _coverImage
    property string _ambienceFilePath: "/usr/share/ambience/" + dialog._packageName +
                                       "/" + dialog._packageName + ".ambience"
    property bool _installing
    property bool _waitForConnection
    property bool _ready
    property bool _shown

    // There's no good way to handle dialog dismiss. With monitoring
    // 'visible' property + couple of other properties we can decide what's
    // the right action to do.
    // Cases to handle:
    // - User taps area outside of it -> dismiss, destroy
    // - User taps install -> dismiss it, but don't destroy
    // - TOH is attached and detached -> dismiss, destroy
    property bool _finished: !visible && !_installing && _ready && _shown

    function installOtherHalf(id) {
        if (id ===_tohId) {
            return
        }

        _tohId = id
        if (_tohId == "") {
            console.log("Could not read TOH ID")            
            destroy(200)
            return
        }

        if (jollaStore.connectionState === JollaStore.Ready) {
            jollaStore.activateTheOtherHalf(_tohId)
        } else {
            _waitForConnection = true
        }
    }

    function cancelOtherHalfInstallation() {
        // This actually means that other half was removed while this SystemDialog
        // is still visible i.e. user has attached and detached the TOH.
        dialog.lower()

        // If TOH/ambience package is alrady being installed cancel the installation
        // and dissmis the Ambience switcher in home
        if (dialog._installing) {
            dbusConnector.cancelledAmbience(dialog._ambienceFilePath)
            // PackageKit does not support cancelling of ongoing transactions
        }
        destroy(200)
    }

    // Copy-paste code from the ApplicationData    
    function install()
    {
        function closure(store, contentModel, appData)
        {
            return function(success)
            {
                if (success) {
                    // Notify switcher about ambience installation
                    dbusConnector.installedAmbience("/usr/share/ambience/" + appData._packageName, appData._tohId)
                    store.updateInstalledOn(appData._uuid)
                } else {
                    // TODO: What to really do here. Error might be that there's no updatable candidate
                    // available or something else.
                    dbusConnector.cancelledAmbience(appData._ambienceFilePath)
                }
                // This notifies the dialog that it can be destroyed
                appData._installing = false
            }
        }

        installedModel.addApplication(dialog._uuid)
        jollaStore.postStoreInstalled(dialog._uuid)
        packageHandler.install(dialog._packageName,
                               closure(jollaStore, installedModel, dialog))
    }

    function checkPackage()
    {
        // Get rid of fast double taps, which might cause two or more installations
        if (_installing) {
            return
        }

        dialog._installing = true
        dialog.lower()
        dbusConnector.installingAmbience(dialog._ambienceFilePath, dialog._packageTitle, dialog._coverImage)
        packageHandler.checkInstalled(dialog._packageName)
    }

    function refreshApplicationData()
    {
        var data = jollaStore.applicationData(dialog._uuid)
        if (data.hasOwnProperty("uuid")) {
            // TODO data.title could be used here too to show the package title, but
            //      due SystemDialog bug it doesn't get updated.
            dialog._descriptionText = data.summary
            dialog._packageTitle = data.title
            dialog.title = data.title
            dialog._coverImage = data.cover !== "" ? data.cover : data.icon
            dialog._ready = true

            if (!dialog.visible && !_installing) {
                dialog.raise()
                dialog.showFullScreen()
            }
        }
    }

    //: Title for The Other Half system dialog
    //% "The Other Half detected"
    title: qsTrId("jolla-store-he-toh_title")
    contentHeight: content.height

    onVisibleChanged: {
        if (visible) {
            mceDbus.displayOn()
        }
    }

    onActiveChanged: {
        if (active) {
            _shown = true
        }
    }

    on_FinishedChanged: {
        if (_finished) {
            destroy(200)
        }
    }

    PolicyValue {
        id: policy
        policyType: PolicyValue.ApplicationInstallationEnabled
    }

    Column {
        id: content
        width: parent.width

        SystemDialogHeader {
            id: header

            title: dialog.title
            description: dialog._descriptionText
        }

        SystemDialogIconButton {
            width: header.width / 2
            anchors.horizontalCenter: parent.horizontalCenter
            //: Install button in The Other Half system dialog
            //% "Install"
            text: qsTrId("jolla-store-bt-toh_install")
            iconSource: (Screen.sizeCategory >= Screen.Large) ? "image://theme/icon-l-add"
                                                              : "image://theme/icon-m-add"
            enabled: dialog._ready
            onClicked: dialog.checkPackage()
            visible: policy.value
        }
        Label {
            height: implicitHeight + 2*Theme.paddingMedium
            visible: !policy.value
            x: Theme.horizontalPageMargin
            width: parent.width - 2*Theme.horizontalPageMargin
            font.pixelSize: Theme.fontSizeLarge
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
            color: Theme.highlightColor
            //% "Other Half installation prevented by Sailfish Device Manager"
            text: qsTrId("jolla-store-other_half_installation_not_allowed")
        }
    }

    // Used for waking up the display
    DBusInterface {
        id: mceDbus

        function displayOn()
        {
            mceDbus.call("req_display_state_on", undefined)
        }

        service: "com.nokia.mce"
        path: "/com/nokia/mce/request"
        iface: "com.nokia.mce.request"
        bus: DBus.SystemBus
    }

    Connections {
        target: jollaStore

        onConnectionStateChanged: {
            if (dialog._waitForConnection && jollaStore.connectionState === JollaStore.Ready) {
                dialog._waitForConnection = false
                jollaStore.activateTheOtherHalf(dialog._tohId)
            }
        }

        onTheOtherHalfActivationReceived: {
            if (data.toh_id === dialog._tohId) {
                dialog._uuid = data.package_uuid
                dialog._packageName = data.package_name
                refreshApplicationData()
            } else {
                dialog.cancelOtherHalfInstallation()
            }
        }

        onApplicationReceived: {
            if (uuid === dialog._uuid) {
                refreshApplicationData()
            }
        }

        onError: {
            console.log("TOH Failure: ", details, "\n")
            dialog.cancelOtherHalfInstallation()
        }
    }

    Connections {
        target: packageHandler

        onCheckInstalledResult: {
            if (dialog._packageName === packageName) {
                if (isInstalled) {
                    // Package is already installed. Give some time for lipstick to
                    // setup everything properly
                    delayedInstallTimer.start()
                } else {
                    // Install package because it's not installed yet.
                    dialog.install()
                }
            }
        }
    }

    // Delay animations for re-activating already installed ambience on purpose.
    // Making animations to happen too fast, makes everything to look too busy.
    Timer {
        id: delayedInstallTimer
        interval: 4500
        onTriggered: {
            dbusConnector.installedAmbience("/usr/share/ambience/" + dialog._packageName, dialog._tohId)
            dialog._installing = false
        }
    }
}
