/****************************************************************************
**
** Copyright (C) 2014 Jolla Ltd.
** Contact: Antti Seppälä <antti.seppala@jollamobile.com>
**
****************************************************************************/
import QtQuick 2.0
import Sailfish.Silica 1.0

SocialImage {
    id: image
    width: Theme.iconSizeMedium
    height: Theme.iconSizeMedium
    fillMode: Image.PreserveAspectCrop
    sourceSize {
        width: image.width
        height: image.height
    }

    Rectangle {
        width: parent.width
        height: parent.height
        color: Theme.highlightColor
        opacity: 0.1
        visible: image.status !== Image.Ready
    }
}
