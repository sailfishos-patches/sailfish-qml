import Nemo.Notifications 1.0

Notification {
    function notify() {
        publish()
        isTransient = true
        summary = ""
        body = ""
        previewSummary = ""
        previewBody = ""
    }

    isTransient: true
    urgency: Notification.Critical
    icon: "icon-s-sd-card"
}
