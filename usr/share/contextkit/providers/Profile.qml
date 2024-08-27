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

    property string _profileName

    propertyValue: {
        switch (propertyName) {
        case "Name":
            return _profileName
        default:
            return undefined
        }
    }

    DBusInterface {
        bus: DBus.SessionBus
        service: "com.nokia.profiled"
        path: "/com/nokia/profiled"
        iface: "com.nokia.profiled"
        signalsEnabled: root.subscribed
        watchServiceStatus: root.subscribed

        function profile_changed(arg, forActiveProfile, profileName) {
            if (forActiveProfile) {
                root._profileName = profileName
            }
        }

        onStatusChanged: {
            if (status === DBusInterface.Available) {
                call("get_profile", [], function(value) {
                    root._profileName = value
                })
            }
        }
    }
}
