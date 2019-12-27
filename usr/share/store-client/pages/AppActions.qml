import QtQuick 2.0

QtObject {
    // Installs given application.
    function install(uuid, packageName) {
        installHandler.install(uuid, packageName)
    }

    // Updates given application.
    function update(uuid, packageName) {
        installHandler.install(uuid, packageName)
    }

    // Uninstalls given application.
    function uninstall(uuid, packageName) {
        packageHandler.uninstall(packageName, false)
    }
}
