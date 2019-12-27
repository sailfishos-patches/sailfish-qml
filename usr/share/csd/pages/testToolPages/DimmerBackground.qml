/*
 * Copyright (c) 2015 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.2
import Sailfish.Silica 1.0

Item {
    id: root

    property alias contentItem: content
    property alias contentWidth: content.width
    property alias contentHeight: content.height

    default property alias _contentItem: content.data

    width: parent.width
    height: contentHeight

    Rectangle {
        anchors.centerIn: content
        width: content.width + Theme.paddingSmall * 2
        height: content.height + Theme.paddingSmall * 2
        radius: Theme.paddingSmall
        visible: content.visible

        color: Theme.overlayBackgroundColor
        opacity: root.enabled ? Theme.highlightBackgroundOpacity : 0.0
        Behavior on opacity { FadeAnimator {} }
    }

    Item {
        id: content
        width: childrenRect.width
        height: childrenRect.height
        anchors.centerIn: parent

        opacity: root.enabled ? 1.0 : 0.0
        Behavior on opacity { FadeAnimator {} }
    }
}
