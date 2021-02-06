/****************************************************************************
**
** Copyright (C) 2013 Jolla Ltd.
** Contact: Vesa Halttunen <vesa.halttunen@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.systemsettings 1.0

Icon {
    id: profileStatusIndicator

    source: profileControl.isSilent ? ("image://theme/icon-status-silent" + iconSuffix)
                                    : ""
    width: source != "" ? implicitWidth : 0
    height: source != "" ? implicitHeight : 0

    ProfileControl {
        id: profileControl

        property bool isSilent: profile == "silent" || profile.ringerVolume == 0
    }
}
