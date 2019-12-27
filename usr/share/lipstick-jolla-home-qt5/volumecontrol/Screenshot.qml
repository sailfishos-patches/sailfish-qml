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

        notification.previewBody = filename
        Lipstick.takeScreenshot(folderPath + filename)
        notification.publish()
    }

    PolicyValue {
        id: policy
        policyType: PolicyValue.ScreenshotEnabled
    }

    Notification {
        id: notification

        //% "Screenshot captured"
        previewSummary: qsTrId("lipstick-jolla-home-la-screenshot_captured")
        isTransient: true
        urgency: Notification.Critical
        icon: "icon-lock-information"
        remoteActions: [ {
            "name": "default",
            "service": "com.jolla.gallery",
            "path": "/com/jolla/gallery/ui",
            "iface": "com.jolla.gallery.ui",
            "method": "showScreenshots"
        }]
    }

    Notification {
        id: policyNotification

        isTransient: true
        urgency: Notification.Critical
        icon: "icon-system-warning"
        //: System notification when MDM policy prevents screenshot being made
        //: %1 is an operating system name without the OS suffix
        //% "Screenshot shortcut disabled by %1 Device Manager"
        previewBody: qsTrId("lipstick-jolla-home-la-screenshot_disallowed_by_policy")
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
