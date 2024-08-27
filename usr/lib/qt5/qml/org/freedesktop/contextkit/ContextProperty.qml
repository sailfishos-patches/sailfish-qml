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

import QtQuick 2.6
import org.freedesktop.contextkit 1.0

Loader {
    id: root

    property string key
    property var value
    readonly property bool subscribed: item && item.subscribed

    property string _namespace
    property string _propertyName

    function subscribe() {
        if (item) {
            item.subscribed = true
        }
    }

    function unsubscribe() {
        if (item) {
            item.subscribed = false
        }
    }

    asynchronous: true

    onKeyChanged: {
        var sepIndex = key.indexOf(".")
        if (sepIndex < 0) {
            console.log("Error: context property key does not contain a '.' namespace qualifier:", key)
            return
        }
        var namespace = key.substring(0, sepIndex)
        _propertyName = key.substring(sepIndex + 1)
        if (_namespace !== namespace) {
            _namespace = namespace
            setSource("/usr/share/contextkit/providers/" + _namespace + ".qml",
                      { "propertyName": _propertyName })
        } else if (status === Loader.Ready) {
            root.item.propertyName = _propertyName
        }
    }

    onStatusChanged: {
        if (status === Loader.Error) {
            console.log("Error: unable to load context object at", source,
                        "for namespace '" + _namespace + "' from key '" + key + "'")
        }
    }

    onLoaded: {
        root.value = Qt.binding(function(){
            return root.item.propertyValue
        })
    }
}
