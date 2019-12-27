import QtQuick 2.0
import Sailfish.Silica 1.0

BackgroundItem {
    id: root
    property int maxHeight: Screen.width*2/3
    property bool expanded
    property bool initialized
    enabled: !storeIf.downloaded && (detailsItem.implicitHeight > (maxHeight + 2*Theme.paddingLarge)) // avoid fading if only tiny amount needs to be expanded
    height: (!enabled || expanded ? detailsItem.implicitHeight : maxHeight) + (moreIcon.enabled ? Theme.paddingMedium : 0)
    highlightedColor: "transparent"
    visible: storeIf.haveDetails

    Behavior on height {
        enabled: initialized
        NumberAnimation {
            duration: detailsItem.implicitHeight > Screen.height ? 400 : 200
            easing.type: Easing.InOutQuad
        }
    }

    onClicked: {
        initialized = true // avoid height transitions when Store backend is still initializing
        expanded = !expanded
    }

    Image {
        id: moreIcon
        enabled: root.enabled
        opacity: enabled ? 1.0 : 0.0
        Behavior on opacity { FadeAnimation {} }
        source: "image://theme/icon-lock-more?"+ (highlighted ? Theme.highlightColor : Theme.primaryColor)
        anchors {
            right: parent.right
            bottom: parent.bottom
            rightMargin: horizontalMargin
        }
    }

    Column {
        id: detailsItem
        anchors.fill: parent
        clip: true
        Label {
            x: horizontalMargin
            width: parent.width - x*2
            color: highlighted || !root.enabled ? Theme.highlightColor : Theme.primaryColor
            visible: storeIf.haveDetails && !storeIf.downloaded
            //: Label for the "what's new" section of the system update
            //% "What's new"
            text: qsTrId("settings_sailfishos-la-whats_new")
        }
        Label {
            id: descriptionLabel
            x: horizontalMargin
            width: parent.width - x*2
            wrapMode: Text.Wrap
            color: highlighted || !root.enabled ? Theme.secondaryHighlightColor : Theme.secondaryColor
            font.pixelSize: Theme.fontSizeExtraSmall
            textFormat: Text.AutoText
            linkColor: root.enabled ? Theme.highlightColor : Theme.primaryColor
            onLinkActivated: Qt.openUrlExternally(link)
            text: storeIf.downloaded
                  ? (haveVoiceCalls
                     //: System update install disclaimer
                     //% "This operation takes some time, in which you're not able to use the device, make or receive any calls or make emergency calls. Device will reboot after installation."
                     ? qsTrId("settings_sailfishos-la-install_disclaimer")
                       //: System update install disclaimer
                       //% "This operation takes some time, in which you're not able to use the device. Device will reboot after installation."
                     : qsTrId("settings_sailfishos-la-install_disclaimer_no_calls"))
                  : storeIf.osSummary
        }
    }
    OpacityRampEffect {
        sourceItem: detailsItem
        enabled: root.enabled && !root.expanded
        direction: OpacityRamp.TopToBottom
        slope: 3
        offset: 2/3
    }
}
