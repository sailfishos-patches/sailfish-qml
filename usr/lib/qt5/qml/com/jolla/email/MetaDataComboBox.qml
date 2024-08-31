/*
 * Copyright (c) 2013 – 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0

CompressibleItem {
    id: root
    property alias menu: comboBox.menu
    property alias label: comboBox.label
    property alias value: comboBox.value
    property alias currentIndex: comboBox.currentIndex

    expandedHeight: comboBox.height ? comboBox.height : comboBox.implicitHeight

    ComboBox {
        id: comboBox
        visible: !root.compressed
        anchors.bottom: parent.bottom
    }
}
