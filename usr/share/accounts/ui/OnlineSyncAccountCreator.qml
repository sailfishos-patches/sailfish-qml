import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import com.jolla.settings.accounts 1.0

QtObject {
    id: root

    property Provider provider
    property var services: []

    property string username
    property string password
    property string serverAddress
    property string addressbookPath
    property string calendarPath
    property string webdavPath
    property var servicesEnabledConfig: ({})

    signal success(int newAccountId)
    signal failed(int errorCode, string errorMessage)
    signal updateCreationStatus(string statusText)

    property bool _startedAccountCreation

    onFailed: {
        _startedAccountCreation = false
    }

    function start() {
        if (_startedAccountCreation) {
            return
        }

        _startedAccountCreation = true

        var servicesConfig = {}
        for (var i = 0; i < services.length; ++i) {
            var config = {}
            if (serverAddress != "") {
                config["server_address"] = serverAddress
            }
            var service = services[i]
            if (service.serviceType === "carddav") {
                if (addressbookPath != "") {
                    config["addressbook_path"] = addressbookPath
                }
            }
            if (webdavPath != "") {
                config["webdav_path"] = webdavPath
            }
            servicesConfig[service.name] = config
        }

        _accountFactory.createAccount(
                provider.name,
                "onlinesync-caldav",    // any onlinesync service name is fine
                username, password,
                username,
                servicesConfig,    // configuration map
                "Jolla",  // applicationName
                "",       // symmetricKey
                "Jolla")  // credentialsName
    }

    function _findCalendarService() {
        for (var i = 0; i < services.length; ++i) {
            var service = services[i]
            if (service.serviceType === "caldav") {
                return service
            }
        }
        return null
    }

    property AccountFactory _accountFactory: AccountFactory {
        onError: {
            console.log("OnlineSync creation error:", message)
            root.failed(errorCode, message)
        }
        onSuccess: {
            // initialize the Account, then search for calendars
            _newAccount.identifier = newAccountId
        }
    }

    property Account _newAccount: Account {
        property bool triggeredCompletion
        onStatusChanged: {
            if (status == Account.Initialized) {
                // enable or disable services as required. TODO: create sync profiles?
                var needSync = false
                for (var i = 0; i < services.length; ++i) {
                    var service = services[i]
                    var enableService = root.servicesEnabledConfig[service.name] === true
                    if (!enableService && isEnabledWithService(service.name)) {
                        disableWithService(service.name)
                        needSync = true
                    } else if (enableService && !isEnabledWithService(service.name)) {
                        enableWithService(service.name)
                        needSync = true
                    }
                }
                if (needSync) {
                    sync()
                } else {
                    triggeredCompletion = true
                    _completeAccountCreation()
                }
            } else if (status == Account.Synced) {
                if (!triggeredCompletion) {
                    triggeredCompletion = true
                    _completeAccountCreation()
                }
            } else if (status == Account.Error) {
                console.log("failed to sync online sync account settings")
                remove()
                root.failed(error, errorMessage)
            }
        }

        function _completeAccountCreation() {
            // enumerate calendars if CalDAV is enabled
            var caldav = root._findCalendarService()
            if (caldav && root.servicesEnabledConfig[caldav.name] === true) {
                if (root._calendarUpdater != null) {
                    root._calendarUpdater.destroy()
                }

                root._calendarUpdater = calendarUpdaterComponent.createObject(root)
                root._calendarUpdater.start(_newAccount,
                                            caldav.name,
                                            configurationValues(caldav.name)["server_address"],
                                            calendarPath)
            } else {
                // otherwise just emit success
                root.success(_newAccount.identifier)
            }
        }
    }

    property QtObject _calendarUpdater
    property Component calendarUpdaterComponent: Component {
        CaldavAccountCalendarUpdater {
            onStatusChanged: {
                root.updateCreationStatus(statusText())
            }
            onSuccess: {
                root.success(_newAccount.identifier)
            }
            onError: {
                _newAccount.remove()
                root.failed(errorCode, errorString)
            }
        }
    }
}
