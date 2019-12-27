import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Lipstick 1.0
import org.nemomobile.lipstick 0.1
import "../systemwindow"

SystemWindow {
    id: root

    property string content
    property bool isUri: true

    property real reservedHeight: ((Screen.sizeCategory < Screen.Large) ? 0.2 * Screen.height : 0.4 * Screen.height) - 1
    property bool verticalOrientation: Lipstick.compositor.topmostWindowOrientation === Qt.PrimaryOrientation
                                    || Lipstick.compositor.topmostWindowOrientation === Qt.PortraitOrientation
                                    || Lipstick.compositor.topmostWindowOrientation === Qt.InvertedPortraitOrientation

    contentHeight: flickable.height

    SystemDialogLayout {
        contentHeight: flickable.height
        onDismiss: root.shouldBeVisible = false
    }

    SilicaFlickable {
        id: flickable

        width: parent.width
        height: Math.min(contentHeight, (verticalOrientation ? Screen.height : Screen.width) - root.reservedHeight)
        contentHeight: contentColumn.height + Theme.paddingLarge
        clip: true

        FontMetrics {
            id: metrics

        }

        Column {
            id: contentColumn
            width: parent.width

            Column {
                width: parent.width

                spacing: Theme.paddingMedium

                SystemDialogHeader {
                    bottomPadding: 0

                    title: openFileModel.isFile
                            //% "Open file"
                            ? qsTrId("lipstick-jolla-home-la-open_file")
                              //% "Open link"
                            : qsTrId("lipstick-jolla-home-la-open_link")
                    //% "Attempting to open"
                    description: qsTrId("lipstick-jolla-home-la-attempting_to_open_file")
                }

                Label {
                    x: (Screen.sizeCategory < Screen.Large) ? Theme.horizontalPageMargin : 0 // Match the padding inside SystemDialogHeader
                    width: parent.width - (2 * x)

                    color: Theme.highlightColor
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideMiddle
                    horizontalAlignment: Text.AlignHCenter
                    text: openFileModel.displayName
                }

                Label {
                    x: (Screen.sizeCategory < Screen.Large) ? Theme.horizontalPageMargin : 0 // Match the padding inside SystemDialogHeader
                    width: parent.width - (2 * x)
                    bottomPadding: Theme.paddingLarge

                    color: Theme.highlightColor
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter

                    //% "Choose an app to continue."
                    text: qsTrId("lipstick-jolla-home-la-choose_application")
                }
            }

            ColumnView {
                width: parent.width

                itemHeight: Theme.itemSizeSmall

                model: openFileModel
                delegate: ListItem {
                    id: actionItem

                    onClicked: {
                        openFileModel.open(index)
                        root.shouldBeVisible = false
                    }

                    HighlightImage {
                        id: icon
                        x: Theme.horizontalPageMargin
                        y: (parent.height - height) / 2
                        width: Theme.iconSizeMedium
                        height: Theme.iconSizeMedium

                        source: {
                            if (actionIcon.indexOf(':/') !== -1 || actionIcon.indexOf("data:image/png;base64") === 0) {
                                return actionIcon
                            } else if (actionIcon.indexOf('/') === 0) {
                                return 'file://' + actionIcon
                            } else if (actionIcon.length) {
                                return 'image://theme/' + actionIcon
                            } else {
                                return ""
                            }
                        }
                        highlighted: actionItem.highlighted
                    }

                    Label {
                        x: icon.x + icon.width + Theme.paddingLarge
                        width: parent.width - x - Theme.horizontalPageMargin
                        height: parent.height
                        text: actionName

                        color: actionItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                        verticalAlignment: Text.AlignVCenter
                        truncationMode: TruncationMode.Fade
                    }
                }
            }
        }
    }
}
