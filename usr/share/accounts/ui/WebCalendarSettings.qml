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

Column {
    property string profileName
    property int accountId
    property string remoteUrl
    property alias label: calendarLabel.text
    property alias allowRedirect: calendarRedirect.checked
    property alias schedule: profileSchedule

    function escapeEntities(data) {
        return data.replace(/[<>&'"]/g, function (c) {
            switch (c) {
            case '<': return '&lt;'
            case '>': return '&gt;'
            case '&': return '&amp;'
            case '\'': return '&apos;'
            case '"': return '&quot;'
            }
        })
    }

    function toXML() {
        return "<profile type=\"sync\" name=\"" + profileName + "\">"
            + "<key value=\"online\" name=\"destinationtype\"/>"
            + "<key value=\"true\" name=\"enabled\"/>"
            + "<key value=\"false\" name=\"hidden\"/>"
            + "<key value=\"true\" name=\"use_accounts\"/>"
            + "<key value=\"" + accountId + "\" name=\"accountid\"/>"
            + "<profile type=\"client\" name=\"webcal\">"
            + "<key value=\"" + (allowRedirect ? "true" : "false") + "\" name=\"allowRedirect\"/>"
            + "<key value=\"" + escapeEntities(remoteUrl) + "\" name=\"remoteCalendar\"/>"
            + "<key value=\"" + escapeEntities(label) + "\" name=\"label\"/>"
            + "</profile>"
            + profileSchedule.toXML()
            + "</profile>"
    }

    function reloadSchedule() {
        scheduleOptions.schedule = null
        scheduleOptions.schedule = profileSchedule
    }

    AccountSyncSchedule {
        id: profileSchedule
        function toIntervalAtt(value) {
            if (value == AccountSyncSchedule.Every5Minutes)      return "interval=\"5\" "
            if (value == AccountSyncSchedule.Every15Minutes)     return "interval=\"15\" "
            if (value == AccountSyncSchedule.Every30Minutes)     return "interval=\"30\" "
            if (value == AccountSyncSchedule.EveryHour)          return "interval=\"60\" "
            if (value == AccountSyncSchedule.TwiceDailyInterval) return "interval=\"720\" "
            return "interval=\"0\" "
        }
        function toDaysAtt(value) {
            var output = ""
            if (value & AccountSyncSchedule.Monday)    output += "1,"
            if (value & AccountSyncSchedule.Tuesday)   output += "2,"
            if (value & AccountSyncSchedule.Wednesday) output += "3,"
            if (value & AccountSyncSchedule.Thursday)  output += "4,"
            if (value & AccountSyncSchedule.Friday)    output += "5,"
            if (value & AccountSyncSchedule.Saturday)  output += "6,"
            if (value & AccountSyncSchedule.Sunday)    output += "7,"
            if (output.length > 0) {
                return "days=\"" + output.slice(0, -1) + "\" "
            } else {
                return "days=\"\" "
            }
        }

        function toXML() {
            return "<schedule enabled=\"" + (enabled ? "true" : "false") + "\" "
                + toIntervalAtt(interval) + toDaysAtt(days) + ">"
                + "<rush enabled=\"" + (peakScheduleEnabled ? "true" : "false") + "\" "
                + "begin=\"" + peakStartTime.toTimeString() + "\" "
                + "end=\"" + peakEndTime.toTimeString() + "\" "
                + toIntervalAtt(peakInterval) + toDaysAtt(peakDays)
                + "/></schedule>"
        }
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
        id: calendarLabel
        width: parent.width
        //% "Leave empty to auto-detect name"
        placeholderText: qsTrId("accounts-settings-lb-webcal_name_auto_detect")
        //% "Calendar name"
        label: qsTrId("accounts-settings-lb-webcal_name")
        EnterKey.iconSource: "image://theme/icon-m-enter-close"
        EnterKey.onClicked: focus = false
    }

    TextSwitch {
        id: calendarRedirect
        //% "Follow HTTP redirect"
        text: qsTrId("accounts-settings-lb-webcal_redirect")
        //% "Allow to follow HTTP redirections when the given URL is a link to another one."
        description: qsTrId("accounts-settings-lb-webcal_redirect_description")
    }

    SyncScheduleOptions {
        id: scheduleOptions
        schedule: profileSchedule
        isSync: true
    }

    Loader {
        width: parent.width
        active: profileSchedule.enabled && profileSchedule.peakScheduleEnabled

        sourceComponent: Component {
            PeakSyncOptions {
                schedule: profileSchedule
            }
        }
    }
}
