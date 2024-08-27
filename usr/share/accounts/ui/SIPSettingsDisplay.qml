import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import com.jolla.settings.accounts 1.0

Column {
    id: root

    property bool autoEnableAccount
    property Provider accountProvider
    property int accountId
    property alias acceptableInput: settings.acceptableInput

    property string _defaultServiceName: "sip"
    property bool _saving

    signal accountSaveCompleted(var success)

    function saveAccount(blockingSave) {
        account.enabled = mainAccountSettings.accountEnabled
        account.displayName = mainAccountSettings.accountDisplayName
        account.enableWithService(_defaultServiceName)

        _saveServiceSettings(blockingSave)
    }

    function _populateServiceSettings() {
        var accountSettings = account.configurationValues(_defaultServiceName)

        for (var i = 0; i < settings.children.length; i++) {
            var item = settings.children[i]

            if (!item._tpType) continue

            var tpValue = accountSettings['telepathy/' + item._tpParam]

            if (!tpValue) continue

            if (item._tpType === 's') {
                item.text = tpValue;

            } else if (item._tpType === 'b') {
                item.checked = tpValue

            } else if (item._tpType === 'e') {
                for (var j = 0; j < item.menu.children.length; j++) {
                    var mi = item.menu.children[j]

                    if (mi._tpValue == tpValue) {
                        item.currentIndex = j
                        break
                    }
                }
            }
        }
    }

    function _saveServiceSettings(blockingSave) {
        account.setConfigurationValue("", "default_credentials_username", settings.account)

        for (var i = 0; i < settings.children.length; i++) {
            var item = settings.children[i]
            var value

            if (!item._tpType) continue

            if (item._tpType == 's')
                value = item.text === '' ? null : item.text
            else if (item._tpType == 'b')
                value = item.checked == item._tpDefault ? null : item.checked
            else if (item._tpType == 'e')
                value = item.currentItem._tpValue == item._tpDefault ? null : item.currentItem._tpValue

            var tpParam = 'telepathy/' + item._tpParam

            if (value !== null) {
                console.log(tpParam + ' = ' + value)
                account.setConfigurationValue(_defaultServiceName, tpParam, value)
            } else {
                console.log(tpParam + ' (removed)')
                account.removeConfigurationValue(_defaultServiceName, tpParam)
            }
        }

        _saving = true
        if (blockingSave) {
            account.blockingSync()
        } else {
            account.sync()
        }
    }

    width: parent.width
    spacing: Theme.paddingLarge

    AccountMainSettingsDisplay {
        id: mainAccountSettings
        accountProvider: root.accountProvider
        accountUserName: account.defaultCredentialsUserName
        accountDisplayName: account.displayName
    }

    SIPCommon {
        id: settings
        enabled: mainAccountSettings.accountEnabled
        opacity: enabled ? 1 : 0
        editMode: true

        Behavior on opacity { FadeAnimation { } }
    }

    Account {
        id: account

        identifier: root.accountId
        property bool needToUpdate

        onStatusChanged: {
            if (status === Account.Initialized) {
                mainAccountSettings.accountEnabled = root.autoEnableAccount || account.enabled
                if (root.autoEnableAccount) {
                    enableWithService(_defaultServiceName)
                }
                root._populateServiceSettings()
            } else if (status === Account.Error) {
                // display "error" dialog
            } else if (status === Account.Invalid) {
                // successfully deleted
            }
            if (root._saving && status != Account.SyncInProgress) {
                root._saving = false
                root.accountSaveCompleted(status == Account.Synced)
            }
        }
    }
}
