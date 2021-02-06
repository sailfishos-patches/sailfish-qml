import QtQuick 2.6
import Sailfish.Silica 1.0
import org.pycage.jollastore 1.0

/* Item representing an application in a list.
 */

ListItem {
    id: listItem

    property alias title: titleLabel.text
    property alias icon: lineIcon.image
    property int progress: 100
    property string version
    property int appState
    property int appSize

    function statusText() {
        if (progress === 0) {
            //: Waiting status text for an application item
            //% "Waiting"
            return qsTrId("jolla-store-la-waiting")
        } else if (progress < 50) {
            //: Downloading status text for an application item
            //% "Downloading"
            return qsTrId("jolla-store-la-downloading")
        } else if (progress < 100) {
            return appState == ApplicationState.Installing
                    //: Installing status text for an application item
                    //% "Installing"
                    ? qsTrId("jolla-store-la-installing")
                    //: Updating status text for an application item
                    //% "Updating"
                    : qsTrId("jolla-store-la-updating")
        }
        return ""
    }


    AppImage {
        id: lineIcon

        opacity: busyIndicator.running || progressCircle.running ? Theme.opacityLow : 1.0
        width: height
        height: Theme.iconSizeLauncher
        anchors {
            left: parent.left
            leftMargin: Theme.paddingLarge
            verticalCenter: parent.verticalCenter
        }
    }

    BusyIndicator {
        id: busyIndicator
        anchors.centerIn: lineIcon
        running: (appState === ApplicationState.Installing
                  || appState === ApplicationState.Updating) && (progress === 0 || progress === 100)
                 || appState === ApplicationState.Uninstalling
    }

    ProgressCircle {
        id: progressCircle
        property bool running: (progress > 0 && progress < 100) && appState !== ApplicationState.Uninstalling
        anchors.fill: busyIndicator
        opacity: running ? 1.0 : 0.0
        Behavior on opacity { FadeAnimator {} }
        progressColor: palette.highlightColor
        backgroundColor: palette.highlightDimmerColor
        value: (progress % 50) / 50.0
        borderWidth: Math.round(Theme.paddingSmall/2)
    }

    Column {
        anchors {
            left: lineIcon.right
            right: parent.right
            margins: Theme.paddingLarge
            verticalCenter: parent.verticalCenter
        }

        Label {
            id: titleLabel
            width: parent.width
            truncationMode: TruncationMode.Fade
            font.pixelSize: Theme.fontSizeSmall
        }

        Flow {
            width: parent.width
            spacing: downloadProgressLabel.y > 0 ? 0 : Theme.paddingMedium

            Label {
                visible: text.length > 0
                font.pixelSize: Theme.fontSizeExtraSmall
                text: statusText()
            }
            Label {
                id: downloadProgressLabel

                color: highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                font.pixelSize: Theme.fontSizeExtraSmall
                //: Download progress fraction, e.g. 25.7MB / 44.3MB
                //% "%1 / %2"
                text: qsTrId("jolla-store-la-download_progress")
                    .arg(Format.formatFileSize(progress / 50.0 * appSize))
                    .arg(Format.formatFileSize(appSize))
                visible: appSize > 0 && progress > 0 && progress < 50 && appState !== ApplicationState.Uninstalling
                width: Math.max(implicitWidth, fontMetrics.advanceWidth("999.9MB / 999.9MB"))
                FontMetrics {
                    id: fontMetrics
                    font: downloadProgressLabel.font
                }
            }
        }
    }
}
