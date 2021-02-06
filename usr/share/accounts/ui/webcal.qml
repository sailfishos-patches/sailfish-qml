/*
 Copyright 2020 Damien Caliste <dcaliste@free.fr>

 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice, this list
    of conditions and the following disclaimer.

 2. Redistributions in binary form must reproduce the above copyright notice, this
    list of conditions and the following disclaimer in the documentation and/or
    other materials provided with the distribution.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
*/

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import com.jolla.settings.accounts 1.0
import Nemo.DBus 2.0

AccountCreationAgent {
    id: agent
    property string remoteUrl

    initialPage: Dialog {
        acceptDestination: busyComponent
        canAccept: calendarUrl.acceptableInput
        onAccepted: remoteUrl = calendarUrl.url()
        onAcceptBlocked: calendarUrl.errorHighlight = true

        Column {
            width: parent.width
            DialogHeader {
                //% "Next"
                acceptText: qsTrId("accounts-settings-lb-webcal-next")
            }

            Item {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                height: icon.height + Theme.paddingLarge
                Image {
                    id: icon
                    width: Theme.iconSizeLarge
                    height: width
                    source: "image://theme/graphic-service-generic-cdav"
                }

                Label {
                    anchors {
                        left: icon.right
                        leftMargin: Theme.paddingLarge
                        right: parent.right
                        verticalCenter: icon.verticalCenter
                    }
                    color: Theme.highlightColor
                    font.pixelSize: Theme.fontSizeLarge
                    truncationMode: TruncationMode.Fade
                    //% "Web calendar"
                    text: qsTrId("accounts-settings-lb-webcal")
                }
            }

            TextField {
                id: calendarUrl

                function url() {
                    // startsWith() was added in Qt5.8
                    if (text.slice(0,7) == 'http://' || text.slice(0,8) == 'https://') {
                        return text
                    } else if (text.slice(0,10) == 'webcals://') {
                        return 'https://' + text.slice(10)
                    } else if (text.slice(0,9) == 'webcal://') {
                        return 'http://' + text.slice(9)
                    } else {
                        return 'http://' + text
                    }
                }

                focus: true
                text: agent.remoteUrl
                //% "Web address"
                label: qsTrId("accounts-settings-la-web_address")
                validator: RegExpValidator { regExp: /^[^.]*\.[^/]*\/.+$/ }
                inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase

                onTextChanged: errorHighlight = false
                onActiveFocusChanged: if (!activeFocus) errorHighlight = !acceptableInput

                description: {
                    if (errorHighlight) {
                        if (text.length === 0) {
                            //% "Web address is required"
                            return qsTrId("components_accounts-la-web_address_required")
                        } else {
                            //% "Valid web address is required"
                            return qsTrId("components_accounts-la-valid_web_address_required")
                        }
                    }
                    return ""
                }
            }
        }
    }

    Component {
        id: busyComponent
        AccountBusyPage {
            id: busy
            //% "Checking calendar URL"
            busyDescription: qsTrId("accounts-settings-lb-webcal_checking")

            Timer {
                id: requestTimer
                interval: 1000
                // Creating a XMLHttpRequest is slow and delay
                // the adjustment of navigation dots...
                onTriggered: {
                    var calRequest = new XMLHttpRequest()
                    calRequest.onreadystatechange = function() {
                        if (calRequest.readyState != XMLHttpRequest.DONE) {
                            return
                        }
                        if (calRequest.status == 200) {
                            var label = remoteUrl
                            var maxAt = calRequest.responseText.indexOf("BEGIN:VEVENT")
                            var at = calRequest.responseText.indexOf("X-WR-CALNAME:")
                            if (at > 0 && at < maxAt) {
                                var end = calRequest.responseText.indexOf("\r\n", at)
                                end = end < 0 ? calRequest.responseText.indexOf("\n", at) : end
                                if (end > 0) {
                                    label = calRequest.responseText.slice(at + 13, end)
                                }
                            }
                            if (calRequest.responseText.indexOf("BEGIN:VCALENDAR") == 0) {
                                pageStack.animatorPush(settingComponent, {"calendarLabel": label})
                            } else {
                                busy.state = "info"
                                //% "Cannot find a calendar. Check that the given URL points to ICS data."
                                busy.infoExtraDescription = qsTrId("accounts-settings-lb-webcal_no_calendar_data")
                            }
                        } else {
                            busy.state = "info"
                            //% "Cannot find any data at given URL."
                            busy.infoExtraDescription = qsTrId("accounts-settings-lb-webcal_no_data")
                        }
                    }
                    calRequest.open("GET", agent.remoteUrl)
                    calRequest.send()
                }
            }

            onStatusChanged: {
                if (status == PageStatus.Active) {
                    requestTimer.start()
                }
            }
        }
    }

    Component {
        id: settingComponent
        Dialog {
            id: settingDialog
            property alias calendarLabel: settings.label
            acceptDestination: agent.endDestination
            acceptDestinationAction: agent.endDestinationAction
            backNavigation: false
            canAccept: false // account.identifier > 0
            onAccepted: {
                if (settings.label.length > 0) {
                    account.displayName = settings.label
                }
                account.sync()
                // Redo the profile update in case the user has changed something.
                msyncd.call("updateProfile", settings.toXML())
            }

            AccountManager {
                id: manager
                onAccountCreated: {
                    account.identifier = accountId
                    account.enabled = true
                    account.displayName = calendarLabel
                    // Account is not notifying identifier changes.
                    settings.accountId = account.identifier
                    settings.profileName = "webcal-sync-" + account.identifier
                    // Start the profile creation as soon as possible due to
                    // the 30 second delay for synchro in Buteo for new profiles.
                    msyncd.call("updateProfile", settings.toXML())
                    settingDialog.canAccept = true
                }
                Component.onCompleted: createAccount("webcal")
            }

            Account {
                id: account
                Component.onDestruction: {
                    if (settingDialog && settingDialog.status == PageStatus.Active
                        && account.identifier > 0) {
                        sync()
                    }
                }
            }

            DBusInterface {
                id: msyncd
                service: "com.meego.msyncd"
                path: "/synchronizer"
                iface: "com.meego.msyncd"
                bus: DBusAdaptor.SessionBus
            }

            SilicaFlickable {
                anchors.fill: parent
                contentHeight: header.height + settings.height

                DialogHeader {
                    id: header
                }

                WebCalendarSettings {
                    id: settings
                    anchors.top: header.bottom
                    width: parent.width
                    // profileName: "webcal-sync-" + account.identifier
                    // accountId: account.identifier
                    remoteUrl: agent.remoteUrl
                    allowRedirect: true
                    schedule.enabled: true
                    Component.onCompleted: schedule.setIntervalSyncMode(
                        AccountSyncSchedule.TwiceDailyInterval,
                        AccountSyncSchedule.Monday
                      + AccountSyncSchedule.Tuesday
                      + AccountSyncSchedule.Wednesday
                      + AccountSyncSchedule.Thursday
                      + AccountSyncSchedule.Friday
                      + AccountSyncSchedule.Saturday
                      + AccountSyncSchedule.Sunday)
                }

                VerticalScrollDecorator {}
            }
        }
    }
}
