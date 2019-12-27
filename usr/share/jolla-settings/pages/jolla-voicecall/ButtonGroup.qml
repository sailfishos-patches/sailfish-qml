/****************************************************************************************
**
** Copyright (C) 2013 Jolla Ltd.
** Contact: Matt Vogt <matthew.vogt@jollamobile.com>
** All rights reserved.
** 
****************************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: root

    implicitWidth: childrenRect.width
    implicitHeight: childrenRect.height

    property Item checkedButton

    property int __silica_buttongroup

    property list<Item> _connectedChildren

    function reset() {
        var firstCheckable = null

        var existing = []
        if (_connectedChildren !== undefined) {
            for (var i = 0; i < _connectedChildren.length; ++i) {
                if (_connectedChildren[i] !== null) {
                    existing.push(_connectedChildren[i])
                }
            }
        }

        _traverseChildren(root, function(child) {
            if (child.hasOwnProperty('__silica_textswitch')) {
                var connected
                for (var i = 0; i < existing.length; ++i) {
                    if (existing[i] === child) {
                        connected = true
                        break
                    }
                }
                if (!connected) {
                    child.clicked.connect(function(){ _childClicked(child) })
                    existing.push(child)
                }

                if (child.checked && checkedButton === null) {
                    checkedButton = child
                } else if (firstCheckable === null) {
                    firstCheckable = child
                }
            }
        })

        _connectedChildren = [ existing ]

        if (checkedButton) {
            _childClicked(checkedButton)
        }
    }

    function _childClicked(clickedChild) {
        checkedButton = clickedChild

        if (clickedChild.checked) {
            _traverseChildren(root, function(child) {
                if (child.hasOwnProperty('__silica_textswitch')) {
                    child.checked = (child === checkedButton)
                }
            })
        }
    }

    function _traverseChildren(obj, cb) {
        for (var i = 0; i < obj.children.length; ++i) {
            var child = obj.children[i]
            if (!child.hasOwnProperty('__silica_buttongroup')) {
                cb(child)
                if (child.hasOwnProperty('children') && (typeof child.children === 'object')) {
                    _traverseChildren(child, cb)
                }
            }
        }
    }

    Component.onCompleted: reset()
}
