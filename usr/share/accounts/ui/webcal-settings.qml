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
import QtQuick.XmlListModel 2.0

AccountSettingsAgent {
    id: agent

    Account {
        id: account
        identifier: accountId
    }

    DBusInterface {
        id: msyncd
        service: "com.meego.msyncd"
        path: "/synchronizer"
        iface: "com.meego.msyncd"
        bus: DBusAdaptor.SessionBus
    }

    // This can be totally removed when moving to Buteo.Profiles
    XmlListModel {
        id: profileModel
        property string remoteCalendar
        property string calendarLabel
        property bool allowRedirect

        query: "/profile/profile/key"
        XmlRole {name: "key"; query: "@name/string()"; isKey: true}
        XmlRole {name: "value"; query: "@value/string()"}

        onStatusChanged: {
            if (status == XmlListModel.Ready) {
                for (var i = 0; i < profileModel.count; i++) {
                    var obj = profileModel.get(i)
                    if (obj.key == "remoteCalendar") {
                        profileModel.remoteCalendar = obj.value
                    } else if (obj.key == "label") {
                        profileModel.calendarLabel = obj.value
                    } else if (obj.key == "allowRedirect") {
                        profileModel.allowRedirect = (obj.value == "true")
                    }
                }
            }
        }
    }
    XmlListModel {
        id: scheduleModel

        xml: profileModel.xml
        query: "/profile/schedule"
        XmlRole {name: "scheduled"; query: "boolean(@enabled)"}
        XmlRole {name: "interval"; query: "@interval/number()"}
        // XmlRole {name: "time"; query: "@time/string()"}
        XmlRole {name: "days"; query: "@days/string()"}
        XmlRole {name: "peakStart"; query: "rush/@begin/string()"}
        XmlRole {name: "peakStop"; query: "rush/@end/string()"}
        XmlRole {name: "peakDays"; query: "rush/@days/string()"}
        XmlRole {name: "peakInterval"; query: "rush/@interval/number()"}
        XmlRole {name: "withPeak"; query: "rush/@enabled cast as xs:boolean"}

        function toInterval(value) {
            if (value === undefined || value == 0) {
                return AccountSyncSchedule.NoInterval
            } else if (value < 10) {
                return AccountSyncSchedule.Every5Minutes
            } else if (value < 20) {
                return AccountSyncSchedule.Every15Minutes
            } else if (value < 45) {
                return AccountSyncSchedule.Every30Minutes
            } else if (value < 120) {
                return AccountSyncSchedule.EveryHour
            }
            return AccountSyncSchedule.TwiceDailyInterval
        }
        function toDays(dayString) {
            var output = 0
            var indices = dayString.split(',')
            for (var i = 0; i < indices.length; i++) {
                if (indices[i] == 1) output += AccountSyncSchedule.Monday
                if (indices[i] == 2) output += AccountSyncSchedule.Tuesday
                if (indices[i] == 3) output += AccountSyncSchedule.Wednesday
                if (indices[i] == 4) output += AccountSyncSchedule.Thursday
                if (indices[i] == 5) output += AccountSyncSchedule.Friday
                if (indices[i] == 6) output += AccountSyncSchedule.Saturday
                if (indices[i] == 7) output += AccountSyncSchedule.Sunday
            }
            return (output > 0) ? output : undefined
        }

        onStatusChanged: {
            if (status == XmlListModel.Ready && count > 0) {
                var obj = get(0)
                settings.schedule.enabled = (obj.scheduled !== undefined) && obj.scheduled
                settings.schedule.setIntervalSyncMode(toInterval(obj.interval),
                    toDays(obj.days))
                settings.schedule.peakScheduleEnabled = (obj.withPeak !== undefined) && obj.withPeak
                settings.schedule.setPeakSchedule(obj.peakStart, obj.peakStop,
                    toInterval(obj.peakInterval), toDays(obj.peakDays))
                settings.reloadSchedule() // AccountSyncSchedule is not reacting to changes.
            }
        }
    }

    Component.onCompleted: {
        msyncd.typedCall("syncProfile", {"type":"s", "value": settings.profileName}, function(data) {
            if (data.length > 0) {
                profileModel.xml = data
            } else {
                profileError.opacity = 1.
            }
        })
    }

    initialPage: Page {
        id: settingsPage
        property bool _deletionRequest

        onPageContainerChanged: {
            if (!pageContainer && !_deletionRequest) {
                msyncd.call("updateProfile", settings.toXML())
                account.displayName = settings.label.length > 0 ? settings.label : settings.remoteUrl
                account.sync()
            }
        }
        SilicaFlickable {
            anchors.fill: parent
            contentHeight: header.height + settings.height + profileError.height

            PullDownMenu {
                MenuItem {
                    //% "Delete account"
                    text: qsTrId("accounts-me-delete_account")
                    onClicked: {
                        agent.accountDeletionRequested()
                        settingsPage._deletionRequest = true
                        pageStack.pop()
                    }
                }

                MenuItem {
                    //% "Sync"
                    text: qsTrId("accounts-me-sync")
                    onClicked: msyncd.call("startSync", settings.profileName)
                }
            }
            PageHeader {
                id: header
                title: accountsHeaderText
            }
            WebCalendarSettings {
                id: settings
                width: parent.width
                anchors.top: header.bottom
                visible: opacity > 0.
                opacity: !profileError.visible && profileModel.status == XmlListModel.Ready ? 1. : 0.
                Behavior on opacity { FadeAnimation {} }
                profileName: "webcal-sync-" + agent.accountId
                accountId: agent.accountId
                label: profileModel.calendarLabel
                remoteUrl: profileModel.remoteCalendar
                allowRedirect: profileModel.allowRedirect
            }
            InfoLabel {
                id: profileError
                anchors.top: header.bottom
                visible: opacity > 0.
                opacity: profileModel.status == XmlListModel.Error ? 1. : 0.
                Behavior on opacity { FadeAnimation {} }
                //% "Cannot retrieve profile information."
                text: qsTrId("accounts-settings-lb-webcal_profile_error")
            }
            VerticalScrollDecorator {}
        }
    }
}
