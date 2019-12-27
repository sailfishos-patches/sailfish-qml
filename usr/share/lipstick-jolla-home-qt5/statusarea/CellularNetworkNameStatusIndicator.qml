/****************************************************************************
**
** Copyright (C) 2013 Jolla Ltd.
** Contact: Vesa Halttunen <vesa.halttunen@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.0
import org.freedesktop.contextkit 1.0
import Sailfish.Silica 1.0
import com.jolla.lipstick 0.1

Row {
    id: cellularNetworkNameStatusIndicator

    property real maxWidth
    property int modem: 1
    property alias homeNetwork: cellularNetworkNameStatusIndicatorHome.text
    property alias visitorNetwork: cellularNetworkNameStatusIndicatorVisitor.text
    property alias color: cellularNetworkNameStatusSeparator.color
    property bool registered: registrationStatus.value === "home" || registrationStatus.value === "roam"
    property bool textVisible: cellularNetworkNameStatusIndicatorHome.text.length || cellularNetworkNameStatusIndicatorVisitor.text.length

    property string _modemContext: Desktop.cellularContext(modem)
    property bool _showHome: cellularNetworkNameStatusIndicatorHome.text != ''
    property bool _showVisitor: cellularNetworkNameStatusIndicatorVisitor.text != ''
    property bool _showSeparator: registrationStatus.value === "roam"

    property real _separatorWidth: cellularNetworkNameStatusSeparator.width + (_showHome ? Theme.paddingSmall : 0) + (_showVisitor ? Theme.paddingSmall : 0)
    property real _maxTextWidth: maxWidth - (_showSeparator ? _separatorWidth : 0)
    property real _maxHomeTextWidth: _maxTextWidth - (_showVisitor ? Math.min(cellularNetworkNameStatusIndicatorVisitor.implicitWidth, (_maxTextWidth/2)) : 0)
    property real _maxVisitorTextWidth: _maxTextWidth - (_showHome ? Math.min(cellularNetworkNameStatusIndicatorHome.implicitWidth, (_maxTextWidth/2)) : 0)

    ContextProperty {
        id: cellularNetworkNameContextProperty
        key: _modemContext + ".NetworkName"
        onValueChanged: cellularNetworkNameStatusIndicator.setNetworkName()
    }

    ContextProperty {
        id: cellularServiceProviderNameContextProperty
        key: _modemContext + ".ServiceProviderName"
        onValueChanged: cellularNetworkNameStatusIndicator.setNetworkName()
    }

    ContextProperty {
        id: registrationStatus
        key: _modemContext + ".RegistrationStatus"
        onValueChanged: cellularNetworkNameStatusIndicator.setNetworkName()
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

        var networkName = cellularNetworkNameContextProperty.value
        if (networkName === undefined) {
            networkName = ""
        } else {
            // toString() in case networkName is a number, e.g. "3"
            networkName = networkName.toString()
        }

        var networkMatches = networkName.trim().match(/([^(]*)(\()(.*)(\))$/)
        if (networkMatches != null) {
            // If we have a value for ServiceProviderName, that should override the home network value
            var spn = cellularServiceProviderNameContextProperty.value
            if (spn) {
                cellularNetworkNameStatusIndicatorHome.text = spn
            } else {
                cellularNetworkNameStatusIndicatorHome.text = networkMatches[1].trim()
            }
            cellularNetworkNameStatusIndicatorVisitor.text = networkMatches[3].trim()
        } else {
            if (registrationStatus.value === "roam") {
                cellularNetworkNameStatusIndicatorHome.text = cellularServiceProviderNameContextProperty.value
                cellularNetworkNameStatusIndicatorVisitor.text = networkName.trim()
            } else {
                cellularNetworkNameStatusIndicatorHome.text = networkName.trim()
                cellularNetworkNameStatusIndicatorVisitor.text = ""
            }
        }
    }
}
