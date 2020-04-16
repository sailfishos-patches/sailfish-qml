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

    property bool _powerSaveMode
    property int _radioState: -1
    property bool _keyboard_available

    // from mce-dev <mce/mode-names.h>
    readonly property int _MCE_RADIO_STATE_MASTER: (1 << 0)
    readonly property int _MCE_RADIO_STATE_CELLULAR: (1 << 1)
    readonly property int _MCE_RADIO_STATE_WLAN: (1 << 2)

    propertyValue: {
        switch (propertyName) {
        case "PowerSaveMode":
            return _powerSaveMode
        case "OfflineMode":
            return _radioState >= 0 && ((_radioState & _MCE_RADIO_STATE_CELLULAR) == 0)
        case "WlanEnabled":
            return _radioState >= 0 && ((_radioState & _MCE_RADIO_STATE_WLAN) != 0)
        case "InternetEnabled":
            return _radioState >= 0 && ((_radioState & _MCE_RADIO_STATE_MASTER) != 0)
        case "KeyboardPresent":
            return _keyboard_available
        case "KeyboardOpen":
            return _keyboard_available
        default:
            return undefined
        }
    }

    DBusInterface {
        bus: DBus.SystemBus
        service: "com.nokia.mce"
        path: "/com/nokia/mce/signal"
        iface: "com.nokia.mce.signal"
        signalsEnabled: root.subscribed

        function psm_state_ind(value) {
            root._powerSaveMode = value
        }

        function radio_states_ind(value) {
            root._radioState = value
        }

        function keyboard_available_state_ind(value) {
            root._keyboard_available = (value === "available")
        }
    }

    DBusInterface {
        bus: DBus.SystemBus
        service: "com.nokia.mce"
        path: "/com/nokia/mce/request"
        iface: "com.nokia.mce.request"
        watchServiceStatus: root.subscribed

        onStatusChanged: {
            if (status === DBusInterface.Available) {
                call("get_radio_states", [], function(value) {
                    root._radioState = value
                })
                call("get_psm_state", [], function(value) {
                    root._powerSaveMode = value
                })
                call("keyboard_available_state_req", [], function(value) {
                    root._keyboard_available = (value === "available")
                })
            }
        }
    }
}
