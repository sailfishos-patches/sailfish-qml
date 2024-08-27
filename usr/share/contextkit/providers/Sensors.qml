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

import QtSensors 5.2
import org.freedesktop.contextkit 1.0

ContextPropertyBase {
    id: root

    readonly property var _orientationNames: [
        "unknown", "top", "bottom", "left", "right", "face", "back"
    ]

    propertyValue: {
        switch (propertyName) {
        case "Orientation":
            var orientation = sensor.reading.orientation
            if (orientation >= 0 && orientation < root._orientationNames.length) {
                return root._orientationNames[orientation]
            }
            return "unknown"
        default:
            return undefined
        }
    }

    OrientationSensor {
        id: sensor

        active: root.subscribed
    }
}
