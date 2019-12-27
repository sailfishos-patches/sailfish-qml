import QtQuick 2.0
import org.pycage.jollastore 1.0
import org.nemomobile.lipstick 0.1

LauncherItem {
    property string packageName
    // Returns if the launcher is intended to be executable by the user.
    property bool isExecutable: filePath.length > 0 && isValid && shouldDisplay

    onPackageNameChanged: {
        filePath = ""
        if (packageName !== "") {
            var files = packageHandler.packageDesktopFiles(packageName)
            // .desktop files placed outside of /usr/share/applications/ have
            // a special meaning and are not meant to launch apps by the user,
            // so we ignore those
            for (var i = 0; i < files.length; i++) {
                if (files[i].indexOf("/usr/share/applications/") === 0) {
                    filePath = files[i]
                    if (isExecutable) {
                        break
                    }
                }
            }
        }
    }
}
