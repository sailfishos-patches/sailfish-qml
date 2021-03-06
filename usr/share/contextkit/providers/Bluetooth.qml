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

import org.freedesktop.contextkit 1.0
import org.kde.bluezqt 1.0 as BluezQt

ContextPropertyBase {
    id: root

    property var _adapter: BluezQt.Manager.usableAdapter
    readonly property bool _valid: !!adapter

    propertyValue: {
        switch (propertyName) {
        case "Enabled":
            return _valid && _adapter.powered
        case "Visible":
            return _valid && _adapter.discoverable
        case "Connected":
            return _valid && _adapter.connected
        case "Address":
            return _valid ? _adapter.address : ""
        default:
            console.log("Unknown property:", propertyName)
            return undefined
        }
    }
}
