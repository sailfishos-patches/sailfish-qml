import QtQuick 2.4
import Sailfish.Silica 1.0

CoverBackground {
    id: phoneCover

    property int itemHeight: availableHeight/maxItemCount
    property int availableHeight: height - coverActionArea.height - 2*Theme.paddingMedium - Theme.paddingSmall
    property int maxItemCount: Math.round(availableHeight/(fontMetrics.height + 2*Theme.paddingSmall))
    property real scaleRatio: Theme.coverSizeLarge.height/327
    property Item idleCover
    property Item inCallCover
    property bool telephonyActive: telephony.active

    function initializeCover() {
        if (telephonyActive) {
            if (!inCallCover) {
                var inCallCoverComponent = Qt.createComponent("InCallCover.qml")
                if (inCallCoverComponent.status === Component.Ready) {
                    inCallCover = inCallCoverComponent.createObject(phoneCover)
                } else {
                    console.log(inCallCoverComponent.errorString())
                }
            }
        } else {
            if (!idleCover) {
                var idleCoverComponent = Qt.createComponent("IdleCover.qml")
                if (idleCoverComponent.status === Component.Ready) {
                    idleCover = idleCoverComponent.createObject(phoneCover)
                } else {
                    console.log(idleCoverComponent.errorString())
                }
            }
        }
    }

    Component.onCompleted: initializeCover()
    onTelephonyActiveChanged: initializeCover()

    FontMetrics {
        id: fontMetrics
        font.pixelSize: Theme.fontSizeMedium
    }
}
