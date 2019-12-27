import QtQuick 2.0
import QtQuick.Window 2.1 as QtQuick
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0
import Nemo.Notifications 1.0 as NemoNotifications
import Nemo.DBus 2.0
import org.nemomobile.lipstick 0.1

SystemDialog {
    id: root

    property var promptConfig: ({})
    property bool windowVisible: visibility != QtQuick.Window.Hidden &&
                                 visibility != QtQuick.Window.Minimized

    property string title
    property string connectionBus

    signal done(var window, bool unregister)

    function closeDialog(window) {
        flickable.focus = true
        done(window, false)
    }

    function init(promptConfig) {
        root.promptConfig = promptConfig

        var title
        root.connectionBus = promptConfig.connectionBus

        if (promptConfig.mountable) {
            title = promptConfig.label
            if (!title) {
                //: Inserted media storage name, e.g. "25 GB media inserted"
                //% "%1 media inserted"
                title = qsTrId("%1 media inserted").arg(Format.formatFileSize(promptConfig.size, 1))
            }
        }

        if (promptConfig.encrypted || !title) {
            title = promptConfig.vendor + promptConfig.model
        }

        root.title = title
        encryptedInterface.path = promptConfig.objectPath

        if (promptConfig.encrypted) {
            raise()
            show()
        } else {
            notification.publish()
        }
    }

    onDismissed: closeDialog(root)

    contentHeight: flickable.height

    NemoNotifications.Notification {
        id: notification

        previewSummary: connectionBus === "usb"
                          //% "USB storage inserted"
                        ? qsTrId("lipstick-jolla-home-la-usb_storage_inserted")
                          //% "Memory card inserted"
                        : qsTrId("lipstick-jolla-home-la-memory_card_inserted")
        previewBody: root.title

        isTransient: true
        icon: "icon-m-sd-card"
        remoteActions: [ {
                "name": "default",
                "service": "com.jolla.settings",
                "path": "/com/jolla/settings/ui",
                "iface": "com.jolla.settings.ui",
                "method": "showPage",
                "arguments": [ "system_settings/system/storage" ],
            }]
    }

    Component {
        id: errorNotificationComponent
        NemoNotifications.Notification {
            isTransient: true
            urgency: NemoNotifications.Notification.Critical
            icon: "icon-s-sd-card"
        }
    }


    SilicaFlickable {
        id: flickable

        width: parent.width
        height: Math.min(root.height * 0.5, flickable.contentHeight)
        contentHeight: content.height

        Column {
            id: content

            width: parent.width

            SystemDialogHeader {
                title: connectionBus === "usb"
                         //: Encrypted usb storage unlock dialog header
                         //% "Unlock USB storage"
                       ? qsTrId("lipstick-jolla-home-he-usb_storage_encrypted_unlock")
                         //: Encrypted memory card unlock dialog header
                         //% "Unlock memory card"
                       : qsTrId("lipstick-jolla-home-he-memory_card_encrypted_unlock")

                topPadding: Screen.sizeCategory >= Screen.Large ? 2*Theme.paddingLarge : Theme.paddingLarge
                bottomPadding: Theme.paddingLarge
            }

            Label {
                x: Theme.horizontalPageMargin

                width: parent.width - 2 * x
                wrapMode: Text.WordWrap
                color: Theme.highlightColor

                text: connectionBus === "usb"
                        //: Encrypted usb storage unlocking description, device name is passed as argument.
                        //% "Enter password to access encrypted data on usb storage %1"
                      ? qsTrId("lipstick-jolla-home-la-usb_storage_unlock_description").arg(root.title)
                        //: Encrypted memory card unlocking description, device name is passed as argument.
                        //% "Enter password to access encrypted data on memory card %1"
                      : qsTrId("lipstick-jolla-home-la-memory_card_unlock_description").arg(root.title)
            }

            Item {
                width: 1; height: Theme.paddingMedium
            }

            PasswordField {
                id: passwordInput

                focus: true
                focusOutBehavior: FocusBehavior.KeepFocus

                color: Theme.highlightColor
                cursorColor: Theme.highlightColor
                placeholderColor: Theme.secondaryHighlightColor

                EnterKey.enabled: text.length > 0
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.onClicked: encryptedInterface.unlock(text)
            }

            Item {
                width: 1; height: Theme.paddingMedium
            }

            Row {
                width: parent.width
                height: Math.max(cancelButton.implicitHeight, unlockButton.implicitHeight)

                SystemDialogTextButton {
                    id: cancelButton
                    width: parent.width / 2
                    height: parent.height
                    //% "Cancel"
                    text: qsTrId("lipstick-jolla-home-bt-cancel")
                    bottomPadding: topPadding
                    onClicked: closeDialog(root)
                }
                SystemDialogTextButton {
                    id: unlockButton
                    width: parent.width / 2
                    height: parent.height
                    enabled: passwordInput.text.length > 0
                    //% "Unlock"
                    text: qsTrId("lipstick-jolla-home-bt-unlock")
                    bottomPadding: topPadding
                    onClicked: encryptedInterface.unlock(passwordInput.text)
                }
            }
        }

        VerticalScrollDecorator {}
    }

    DBusInterface {
        id: encryptedInterface

        bus: DBus.SystemBus

        service: "org.freedesktop.UDisks2"
        iface: "org.freedesktop.UDisks2.Encrypted"

        function unlock(password) {
            // Lower the window and wait for callback.
            root.lower()
            call("Unlock", [ password, {} ],
                 function(success) {
                     encryptedInterface.iface = "org.freedesktop.UDisks2.Filesystem"
                     encryptedInterface.call("Mount", [{"fstype":""}], function(success) {
                         root.closeDialog(root)
                     }, function (error, message) {
                         root.closeDialog(root)
                     })
                 },
                 function(error, message) {
                     console.info("Memory card unlocking error:", error, "message:", message)
                     var errorNotification = errorNotificationComponent.createObject(root)

                    if (error === "org.freedesktop.UDisks2.Error.NotAuthorized" ||
                            error === "org.freedesktop.UDisks2.Error.NotAuthorizedCanObtain" ||
                            error === "org.freedesktop.UDisks2.Error.NotAuthorizedDismissed") {
                        errorNotification.previewBody = connectionBus === "usb"
                                  //% "USB storage unlocking not authorized"
                                ? qsTrId("lipstick-jolla-home-la-usb_storage_unlocking_not_authorized")
                                  //% "Memory card unlocking not authorized"
                                : qsTrId("lipstick-jolla-home-la-memory_card_unlocking_not_authorized")
                    } else {
                        // org.freedesktop.UDisks2.Error.Failed
                        errorNotification.previewBody = connectionBus === "usb"
                                  //% "USB storage unlocking not permitted"
                                ? qsTrId("lipstick-jolla-home-la-usb_storage_unlocking_not_permitted")
                                  //% "Memory card unlocking not permitted"
                                : qsTrId("lipstick-jolla-home-la-memory_card_unlocking_not_permitted")
                    }

                    errorNotification.publish()
                    root.closeDialog(root)
                 })
        }
    }

    DBusInterface {
        bus: DBus.SystemBus
        service: 'com.nokia.mce'
        path: '/com/nokia/mce/signal'
        iface: 'com.nokia.mce.signal'
        signalsEnabled: true

        function display_status_ind(state) {
            if (state === "off") {
                root.closeDialog(root)
            }
        }
    }
}

