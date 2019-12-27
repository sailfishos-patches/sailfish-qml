/****************************************************************************
**
** Copyright (C) 2013 Jolla Ltd.
** Contact: Petri M. Gerdt <petri.gerdt@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0

ContextMenu {
    id: form

    property alias fields: dynamicFields.fields
    property string servicePath
    property bool eap

    property bool _responded

    signal send(variant formData)
    signal closeDialog()
    signal cancel()

    function respond() {
        if (_responded)
            return

        _responded = true
        if (eap)
            send(eapFields.result())
        else
            send(dynamicFields.formData)
    }

    _closeOnOutsideClick: false

    onActiveChanged: {
        if (active) {
            _responded = false
            if (eap)
                eapFields.focus()
            else
                dynamicFields.focus()
        } else if (!_responded) {
            _responded = true
            cancel()
        }
    }

    EapForm {
        id: eapFields
        visible: eap
        servicePath: form.servicePath
        onCloseDialog: form.closeDialog()
        onEnterKeyClicked: form.respond()
    }
    DynamicFields {
        id: dynamicFields
        visible: !eap
        onEnterKeyClicked: form.respond()
    }
    Row {
        width: parent.width
        MouseArea {
            objectName: "CredentialsForm_cancel"
            width: Math.round(parent.width / 2)
            height: Theme.itemSizeSmall
            onClicked: {
                form.cancel()
                dynamicFields.cancel()
            }
            Label {
                x: 2*Theme.paddingLarge
                //% "Cancel"
                text: qsTrId("lipstick-jolla-home-bt-cancel")
                color: parent.pressed && parent.containsMouse ? Theme.highlightColor : Theme.primaryColor
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        MouseArea {
            objectName: "CredentialsForm_respond"
            width: Math.round(parent.width / 2)
            height: Theme.itemSizeSmall
            enabled: eap ? eapFields.canAccept : true
            onClicked: form.respond()
            Label {
                //% "Connect"
                text: qsTrId("lipstick-jolla-home-bt-connect")
                opacity: parent.enabled ? 1.0 : Theme.opacityLow
                color: parent.pressed && parent.containsMouse ? Theme.highlightColor : Theme.primaryColor
                anchors {
                    right: parent.right
                    rightMargin: 2*Theme.paddingLarge
                    verticalCenter: parent.verticalCenter
                }
            }
        }
    }
}
