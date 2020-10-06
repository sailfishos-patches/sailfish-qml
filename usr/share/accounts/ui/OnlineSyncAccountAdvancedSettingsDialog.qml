/*
 * Copyright (c) 2013 - 2019 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import com.jolla.settings.accounts 1.0

Dialog {
    id: root

    property Account account
    property var services
    property alias title: header.title

    signal settingsChanged()

    function _save() {
        advancedSettings.saveChanges(root.account, root.services)
        root.settingsChanged()
    }

    acceptDestination: advancedSettings.calendarPathModified
                       ? calendarUpdatePageComponent
                       : null

    onAccepted: {
        if (acceptDestination == null) {
            _save()
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        height: contentColumn.height

        Column {
            id: contentColumn

            width: parent.width

            DialogHeader {
                id: header
            }

            OnlineSyncAccountAdvancedSettings {
                id: advancedSettings

                Component.onCompleted: {
                    load(root.account, root.services)
                }
            }
        }
    }

    Component {
        id: calendarUpdatePageComponent

        OnlineCalendarUpdatePage {
            account: root.account
            serviceName: advancedSettings.calendarServiceName
            serverAddress: advancedSettings.calendarServerAddress
            calendarPath: advancedSettings.calendarPath

            onFinished: {
                if (success) {
                    root._save()
                    pageStack.animatorPush(pageStack.previousPage(root), {}, PageStackAction.Replace)
                }
            }
        }
    }
}
