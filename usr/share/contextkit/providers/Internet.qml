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

import Connman 0.2
import org.freedesktop.contextkit 1.0

ContextPropertyBase {
    id: root

    property var _networkService: networkManager.defaultRoute

    function _networkTypeString(networkType) {
        switch (networkType) {
        case "wifi":
            return "WLAN"
        case "gprs":
        case "cellular":
        case "edge":
        case "umts":
            return "GPRS"
        case "ethernet":
            return "ethernet"
        }
        return ""
    }

    function _networkStateString(networkState) {
        switch (networkState) {
        case "offline":
        case "idle":
            return "disconnected"
        case "online":
        case "ready":
            return "connected"
        }
        return ""
    }

    propertyValue: {
        switch (propertyName) {
        case "NetworkType":
            return _networkService ? _networkTypeString(_networkService.type) : ""
        case "NetworkState":
            return _networkService ? _networkStateString(_networkService.state) : "disconnected"
        case "NetworkName":
            return _networkService ? _networkService.name : ""
        case "SignalStrength":
            return _networkService ? _networkService.strength : 0
        case "Tethering":
            return wlanNetworkTechnology.tethering

        default:
            return undefined
        }
    }

    NetworkManager {
        id: networkManager
    }

    NetworkTechnology {
        id: wlanNetworkTechnology

        path: networkManager.WifiTechnology
    }
}
