import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.devicelock 1.0
import com.jolla.settings.system 1.0
import Sailfish.Policy 1.0

Page {
    id: sideloadingSettingsPage

    DeviceLockSettings {
        id: deviceLockSettings
    }

    PolicyValue {
        id: policy
        policyType: PolicyValue.SideLoadingSettingsEnabled
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width

            PageHeader {
                //% "Untrusted software"
                title: qsTrId("settings_developermode-he-untrusted_software")
            }

            DisabledByMdmBanner {
                active: !policy.value
            }

            TextSwitch {
                id: sideloadingAllowedSwitch

                enabled: policy.value
                automaticCheck: false
                checked: deviceLockSettings.sideloadingAllowed

                //% "Allow untrusted software"
                text: qsTrId("settings_developermode-bu-allow_untrusted_software")

                //% "Enable installation of software coming from 3rd party stores or downloaded from the internet"
                description: qsTrId("settings_developermode-la-untrusted_software_details")

                onClicked: {
                    deviceLockQuery.authenticate(deviceLockSettings.authorization, function(token) {
                        if (deviceLockSettings.sideloadingAllowed) {
                            deviceLockSettings.setSideloadingAllowed(token, false)
                            deviceLockSettings.authorization.relinquishChallenge()
                            pageStack.pop(sideloadingSettingsPage)
                        } else {
                            var obj = pageStack.currentPage == sideloadingSettingsPage
                                    ? pageStack.animatorPush('DisclaimerDialog.qml')
                                    : pageStack.animatorReplaceAbove(sideloadingSettingsPage, 'DisclaimerDialog.qml')
                            obj.pageCompleted.connect(function(dialog) {
                                dialog.accepted.connect(function() {
                                    deviceLockSettings.setSideloadingAllowed(token, true)
                                    deviceLockSettings.authorization.relinquishChallenge()
                                })
                                dialog.rejected.connect(function() {
                                    deviceLockSettings.authorization.relinquishChallenge()
                                })
                            })
                        }
                    })
                }
            }
        }
        VerticalScrollDecorator {}
    }

    DeviceLockQuery {
        id: deviceLockQuery
        returnOnCancel: true
    }
}
