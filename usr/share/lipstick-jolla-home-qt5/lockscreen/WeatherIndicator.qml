/****************************************************************************
**
** Copyright (C) 2018 Jolla Ltd.
** Contact: Bea Lam <bea.lam@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Weather 1.0 as Weather
import org.nemomobile.lipstick 0.1

Weather.WeatherIndicator {
    autoRefresh: true
    active: Lipstick.compositor.lockScreenLayer.active
}
