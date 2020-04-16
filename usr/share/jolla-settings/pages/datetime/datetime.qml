/****************************************************************************
**
** Copyright (c) 2013-2019 Jolla Ltd.
** Copyright (c) 2019 Open Mobile Platform LLC.
** License: Proprietary
**
****************************************************************************/
import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Timezone 1.0
import Sailfish.Policy 1.0
import com.jolla.settings.system 1.0
import org.nemomobile.systemsettings 1.0

Page {
    SilicaFlickable {
        id: listView

        anchors.fill: parent
        contentHeight: content.height

        Column {
            width: parent.width

            PageHeader {
                //% "Time and Date"
                title: qsTrId("settings_datetime-he-time_date")
            }

            AllDateTimeSettingsDisplay {
                dateTimeSettings: DateTimeSettings {}
            }
        }
    }
}
