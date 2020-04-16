/****************************************************************************
**
** Copyright (c) 2013 - 2020 Jolla Ltd.
** Copyright (c) 2019 Open Mobile Platform LLC.
**
** License: Proprietary
**
****************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import MeeGo.QOfono 0.2
import com.jolla.lipstick 0.1
import org.nemomobile.ofono 1.0

Row {
    id: cellularNetworkNameStatusIndicator

    property string modemPath
    property real maxWidth
    property alias homeNetwork: cellularNetworkNameStatusIndicatorHome.text
    property alias visitorNetwork: cellularNetworkNameStatusIndicatorVisitor.text
    property alias color: cellularNetworkNameStatusSeparator.color
    property bool registered: _networkRegistrationStatus === "registered" || _networkRegistrationStatus === "roaming"
    property bool textVisible: cellularNetworkNameStatusIndicatorHome.text.length || cellularNetworkNameStatusIndicatorVisitor.text.length

    property bool _showHome: cellularNetworkNameStatusIndicatorHome.text != ''
    property bool _showVisitor: cellularNetworkNameStatusIndicatorVisitor.text != ''
    property bool _showSeparator: _networkRegistrationStatus === "roaming"

    property real _separatorWidth: cellularNetworkNameStatusSeparator.width + (_showHome ? Theme.paddingSmall : 0) + (_showVisitor ? Theme.paddingSmall : 0)
    property real _maxTextWidth: maxWidth - (_showSeparator ? _separatorWidth : 0)
    property real _maxHomeTextWidth: _maxTextWidth - (_showVisitor ? Math.min(cellularNetworkNameStatusIndicatorVisitor.implicitWidth, (_maxTextWidth/2)) : 0)
    property real _maxVisitorTextWidth: _maxTextWidth - (_showHome ? Math.min(cellularNetworkNameStatusIndicatorHome.implicitWidth, (_maxTextWidth/2)) : 0)

    property string _networkName: networkRegistration.valid ? networkRegistration.name : ""
    property string _networkRegistrationStatus: networkRegistration.valid ? networkRegistration.status : ""
    property string _serviceProviderName: simInfo.valid ? simInfo.serviceProviderName : ""

    on_NetworkNameChanged: setNetworkName()
    on_NetworkRegistrationStatusChanged: setNetworkName()
    on_ServiceProviderNameChanged: setNetworkName()

    OfonoNetworkRegistration {
        id: networkRegistration
        modemPath: cellularNetworkNameStatusIndicator.modemPath
    }

    OfonoSimInfo {
        id: simInfo
        modemPath: cellularNetworkNameStatusIndicator.modemPath
    }

    visible: fakeOperator !== "" || (registered && textVisible)

    width: Math.min(implicitWidth, maxWidth)
    height: childrenRect.height
    spacing: Theme.paddingSmall

    Label {
        id: cellularNetworkNameStatusIndicatorHome
        width: Math.min(implicitWidth, _maxHomeTextWidth)
        color: cellularNetworkNameStatusIndicator.color
        font {
            pixelSize: Theme.fontSizeMedium
            family: Theme.fontFamilyHeading
        }
        truncationMode: TruncationMode.Fade
    }
    Label {
        id: cellularNetworkNameStatusSeparator
        font {
            pixelSize: Theme.fontSizeMedium
            family: Theme.fontFamilyHeading
        }
        text: String.fromCharCode(0x2022) // bullet
        visible: _showSeparator
    }
    Label {
        id: cellularNetworkNameStatusIndicatorVisitor
        width: Math.min(implicitWidth, _maxVisitorTextWidth)
        color: cellularNetworkNameStatusIndicator.color
        font {
            pixelSize: Theme.fontSizeMedium
            family: Theme.fontFamilyHeading
        }
        truncationMode: TruncationMode.Fade
    }

    function setNetworkName() {
        if (fakeOperator !== "") {
            cellularNetworkNameStatusIndicatorHome.text = fakeOperator
            return
        }

        var networkName = _networkName
        if (networkName === undefined) {
            networkName = ""
        } else {
            // toString() in case networkName is a number, e.g. "3"
            networkName = networkName.toString()
        }

        var networkMatches = networkName.trim().match(/([^(]*)(\()(.*)(\))$/)
        if (networkMatches != null) {
            // If we have a value for ServiceProviderName, that should override the home network value
            var spn = _serviceProviderName
            if (spn) {
                cellularNetworkNameStatusIndicatorHome.text = spn
            } else {
                cellularNetworkNameStatusIndicatorHome.text = networkMatches[1].trim()
            }
            cellularNetworkNameStatusIndicatorVisitor.text = networkMatches[3].trim()
        } else {
            if (_networkRegistrationStatus === "roaming") {
                cellularNetworkNameStatusIndicatorHome.text = _serviceProviderName
                cellularNetworkNameStatusIndicatorVisitor.text = networkName.trim()
            } else {
                cellularNetworkNameStatusIndicatorHome.text = networkName.trim()
                cellularNetworkNameStatusIndicatorVisitor.text = ""
            }
        }
    }
}
