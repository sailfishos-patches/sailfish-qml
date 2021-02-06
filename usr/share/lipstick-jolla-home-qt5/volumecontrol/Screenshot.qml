/****************************************************************************
**
** Copyright (c) 2013 - 2019 Jolla Ltd.
** Copyright (c) 2020 Open Mobile Platform LLC.
**
** License: Proprietary
**
****************************************************************************/

import QtQuick 2.0
import org.nemomobile.ngf 1.0
import com.jolla.lipstick 0.1
import org.nemomobile.lipstick 0.1
import org.nemomobile.notifications 1.0
import org.nemomobile.systemsettings 1.0
import Sailfish.Silica 1.0
import QtFeedback 5.0
import Sailfish.Policy 1.0

Item {
    function capture() {
        // If screen is blanked cancel the capture
        if (!Lipstick.compositor.visible) {
            return
        }

        if (!policy.value) {
            policyNotification.publish()
            return
        }

        shutterEvent.play()
        themeEffect.play()

        var folderPath = StandardPaths.pictures + "/Screenshots/"
        if (!fileUtils.exists(folderPath)) {
            fileUtils.mkdir(folderPath)
        }

        //: Filename of a captured screenshot, e.g. "Screenshot_1"
        //% "Screenshot_%1"
        var filename = fileUtils.uniqueFileName(folderPath, qsTrId("lipstick-jolla-home-la-screenshot") + ".png")

        notification.body = filename
        notification.screenshotFilePath = folderPath + filename
        Lipstick.takeScreenshot(notification.screenshotFilePath)
        notification.publish()
    }

    PolicyValue {
        id: policy
        policyType: PolicyValue.ScreenshotEnabled
    }

    Notification {
        id: notification

        property string screenshotFilePath

        appName: Lipstick.notificationSystemApplicationName
        //% "Screenshot captured"
        summary: qsTrId("lipstick-jolla-home-la-screenshot_captured")
        urgency: Notification.Critical
        appIcon: "icon-lock-information"
        remoteActions: [
            remoteAction(
                "default",
                "",
                "com.jolla.gallery",
                "/com/jolla/gallery/ui",
                "com.jolla.gallery.ui",
                "openFile",
                [ notification.screenshotFilePath ]
            ),
            remoteAction(
                "",
                //: Share screenshot image
                //% "Share"
                qsTrId("lipstick-jolla-home-la-share_screenshot"),
                "com.jolla.gallery",
                "/com/jolla/gallery/ui",
                "com.jolla.gallery.ui",
                "shareFile",
                [ notification.screenshotFilePath ]
            ),
            remoteAction(
                "",
                //: Edit screenshot image
                //% "Edit"
                qsTrId("lipstick-jolla-home-la-edit_screenshot"),
                "com.jolla.gallery",
                "/com/jolla/gallery/ui",
                "com.jolla.gallery.ui",
                "editFile",
                [ notification.screenshotFilePath ]
            ),
        ]
    }

    Notification {
        id: policyNotification

        isTransient: true
        urgency: Notification.Critical
        appIcon: "icon-system-warning"
        //: System notification when MDM policy prevents screenshot being made
        //: %1 is an operating system name without the OS suffix
        //% "Screenshot shortcut disabled by %1 Device Manager"
        body: qsTrId("lipstick-jolla-home-la-screenshot_disallowed_by_policy")
            .arg(aboutSettings.baseOperatingSystemName)
    }

    NonGraphicalFeedback {
        id: shutterEvent
        event: "camera_shutter"
    }
    ThemeEffect {
        id: themeEffect
        effect: ThemeEffect.PressWeak
    }
    FileUtils { id: fileUtils }
    AboutSettings {
        id: aboutSettings
    }
}
