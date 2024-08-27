/*
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
 * 02110-1301 USA
 *
 * http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html
 */

import Nemo.DBus 2.0
import org.freedesktop.contextkit 1.0

ContextPropertyBase {
    id: root

    property bool _alarmPresent
    property var _alarmTriggers: ({})

    propertyValue: {
        switch (propertyName) {
        case "Present":
            return _alarmPresent
        case "Triggers":
            return _alarmTriggers
        default:
            return undefined
        }
    }

    DBusInterface {
        bus: DBus.SystemBus
        service: "com.nokia.time"
        path: "/com/nokia/time"
        iface: "com.nokia.time"
        signalsEnabled: root.subscribed
        watchServiceStatus: root.subscribed

        function alarm_present_changed(value) {
            root._alarmPresent = value
        }

        function alarm_triggers_changed(value) {
            root._alarmTriggers = value
        }

        onStatusChanged: {
            if (status === DBusInterface.Available) {
                call("get_alarm_present", [], function(value) {
                    root._alarmPresent = value
                })
                call("get_alarm_triggers", [], function(value) {
                    root._alarmTriggers = value
                })
            }
        }
    }
}
