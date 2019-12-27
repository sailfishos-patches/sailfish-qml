import QtQuick 2.0
import Sailfish.Silica 1.0
import org.pycage.jollastore 1.0

Page {
    id: page

    property string packageName

    property bool _condition: status === PageStatus.Active &&
                              jollaStore.connectionState === JollaStore.Ready

    on_ConditionChanged: {
        if (_condition) {
            jollaStore.resolvePackage(packageName)
            timeoutTimer.start()

            // destroy the binding to not trigger anymore
            _condition = false
        }
    }

    Connections {
        target: jollaStore

        onPackageResolved: {
            if (packageName === page.packageName) {
                if (uuid.length) {
                    var props = { "application": uuid }
                    pageStack.replace(Qt.resolvedUrl("AppPage.qml"), props, PageStackAction.Immediate)
                } else {
                    placeholder.enabled = true
                }
            }
        }
    }

    PageHeader {
        //: Page header for the Store deeplink loading page
        //% "Jolla Store"
        title: qsTrId("jolla-store-he-welcome")
    }

    BusyIndicator {
        anchors.centerIn: parent
        running: ! placeholder.enabled
        size: BusyIndicatorSize.Large
    }

    Timer {
        id: timeoutTimer
        interval: 5000

        onTriggered: {
            placeholder.enabled = true
        }
    }

    ViewPlaceholder {
        id: placeholder
        enabled: false
        //: View placeholder when a certain package could not be found in the store.
        //: Takes the name of the package as parameter.
        //% "Package '%1' was not found in store."
        text: qsTrId("jolla-store-li-no_such_package_in_store").arg(packageName)
    }

}
