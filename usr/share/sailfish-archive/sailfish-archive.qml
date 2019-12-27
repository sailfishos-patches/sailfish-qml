import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.FileManager 1.0
import Nemo.DBus 2.0

ApplicationWindow {
    property QtObject archivePage
    property string coverText

    property bool closing

    readonly property bool canActivate: _coverObject && archivePage
    onCanActivateChanged: {
        if (canActivate) activate()
    }

    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: defaultAllowedOrientations

    opacity: closing ? 0.0 : 1.0
    Behavior on opacity {
        FadeAnimation {
            duration: 1000
            onRunningChanged: {
                if (!running) {
                    Qt.quit()
                }
            }
        }
    }

    // Unregister DBusAdapter from the session bus so that
    // multiple instances can be created.
    Timer {
        id: unregister
        interval: 0
        onTriggered: adapter.destroy()
    }

    DBusAdaptor {
        id: adapter

        service: "org.sailfishos.archive"
        path: "/org/sailfishos/archive"
        iface: "org.sailfishos.archive"

        function open(file) {
            var obj = FileManager.openArchive(file, "/",  StandardPaths.download, PageStackAction.Immediate)
            obj.pageCompleted.connect(function(page) {
                archivePage = page
                archivePage.archiveExtracted.connect(function (containingFolder) {
                    // Pop back to the first page.
                    pageStack.pop(null, PageStackAction.Immediate)
                    var title = containingFolder.substring(StandardPaths.home.length + 1)
                    var directory = pageStack.replace("Sailfish.FileManager.DirectoryPage", {
                                                          path: containingFolder,
                                                          title: title,
                                                          initialPath: containingFolder,
                                                          showDeleteFolder: true,
                                                          //% "Extracted folder"
                                                          description: qsTrId("sailfish-archive-he-extract_folder")
                                                      }, PageStackAction.Immediate)
                    directory.folderDeleted.connect(function () {
                        // Pretty much no way back to anything meaningful. This point
                        // best would be closing application.
                        pageStack.animatorReplace(extractedArchiveFolderDestroyed)
                        //% "No archive open"
                        coverText = qsTrId("sailfish-archive-he-no_open_archive")
                    })
                })
                coverText = archivePage.fileName

                // Activate only after dbus call + cover ready
                if (canActivate) {
                    activate()
                }
                unregister.restart()
            })
        }

        Component.onCompleted: {
            FileManager.init(pageStack)
        }
    }

    Page {
        id: extractedArchiveFolderDestroyed

        SilicaListView {
            anchors.fill: parent

            ViewPlaceholder {
                //: Shown when application is fading away
                //% "Closing..."
                text: closing ? qsTrId("sailfish-archive-la-quiting_application")
                              : //: Shown when extracted archive folder is deleted by user.
                                //% "Extracted archive folder is deleted"
                                qsTrId("sailfish-archive-la-extracted_archive_folder_deleted")

                //% "Pull down to quit the application"
                hintText: closing ? "" : qsTrId("sailfish-archive-la-app_quit_hint")
                enabled: true
            }

            PullDownMenu {
                visible: !closing
                MenuItem {
                    //% "Quit"
                    text: qsTrId("sailfish-archive-me-quit_application")
                    onDelayedClick: closing = true
                }
            }
        }
    }
}
