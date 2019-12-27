import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0
import com.jolla.lipstick 0.1
import Sailfish.Lipstick 1.0
import org.nemomobile.lipstick 0.1
import "../systemwindow"

SystemWindow {
    id: root

    property string title
    property string content
    property bool isUri: true

    property real reservedHeight: ((Screen.sizeCategory < Screen.Large) ? 0.2 * Screen.height : 0.4 * Screen.height) - 1
    property bool verticalOrientation: Lipstick.compositor.topmostWindowOrientation === Qt.PrimaryOrientation
                                    || Lipstick.compositor.topmostWindowOrientation === Qt.PortraitOrientation
                                    || Lipstick.compositor.topmostWindowOrientation === Qt.InvertedPortraitOrientation

    contentHeight: flickable.height

    property alias __silica_applicationwindow_instance: fakeApplicationWindow

    SystemDialogLayout {
        contentHeight: flickable.height
        onDismiss: {
            closeFully()
        }
    }

    Component {
        id: copyContextMenu
        ContextMenu {
            MenuItem {
                //% "Copy"
                text: qsTrId("lipstick-jolla-home-copy_nfc_tag")
                onClicked: Clipboard.text = root.content
            }
        }
    }

    // This binding provides a workaround for JB#44194
    // It ensures the flickable height changes when the context menu is opened/closed
    Binding {
        target: flickable
        property: "height"
        value: Math.min(contentColumn.height, (verticalOrientation ? Screen.height : Screen.width) - root.reservedHeight)
    }

    SilicaFlickable {
        id: flickable

        width: parent.width
        height: Math.min(contentColumn.height, (verticalOrientation ? Screen.height : Screen.width) - root.reservedHeight)
        contentHeight: contentColumn.height
        clip: true

        Column {
            id: contentColumn
            width: parent.width

            SystemDialogHeader {
                id: header

                //% "NFC tag detected"
                title: qsTrId("lipstick-jolla-home-nfc_tag_detected")
                topPadding: transpose ? Theme.paddingLarge : 2*Theme.paddingLarge
            }

            Label {
                id: titleLabel

                width: header.width
                height: implicitHeight + Theme.paddingSmall
                anchors.horizontalCenter: parent.horizontalCenter
                color: Theme.secondaryHighlightColor
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                maximumLineCount: 5
                text: root.title
                visible: text.length > 0
            }

            ListItem {
                id: contentListItem

                width: parent.width
                contentHeight: expandingContent.height
                menu: copyContextMenu
                down: contentMouseArea.pressed

                Expander {
                    id: expandingContent

                    readonly property int availableSpace: (verticalOrientation ? Screen.height : Screen.width)
                                                          - header.height - contentBelowHeader.height
                                                          - (titleLabel.visible ? titleLabel.height : 0)
                                                          - root.reservedHeight
                    collapsedHeight: availableSpace < Theme.itemSizeLarge ? expandedHeight
                                                                          : Math.min(expandedHeight, availableSpace)
                    expandedHeight: contentLabel.height
                    width: parent.width - 2 * Theme.paddingMedium
                    anchors.horizontalCenter: parent.horizontalCenter
                    highlighted: contentMouseArea.pressed

                    Label {
                        id: contentLabel

                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Text.Wrap
                        color: Theme.secondaryHighlightColor
                        text: root.content
                        height: Math.max(contentHeight, Theme.itemSizeMedium)
                    }
                }

                // Mouse area is needed to combine Expander with a ContextMenu
                MouseArea {
                    id: contentMouseArea
                    anchors.fill: expandingContent
                    onPressAndHold: contentListItem.openMenu()
                    onClicked: expandingContent.clicked()
                }
            }

            Column {
                id: contentBelowHeader
                width: parent.width
                anchors.horizontalCenter: parent.horizontalCenter

                Item {
                    width: 1
                    height: Theme.paddingLarge
                }

                Row {
                    width: parent.width
                    height: Math.max(openUrlButton.implicitHeight, dismissButton.implicitHeight)

                    SystemDialogTextButton {
                        id: dismissButton
                        width: openUrlButton.visible ? header.width/2 : header.width
                        height: parent.height
                        text: isUri
                              ? //% "Cancel"
                                qsTrId("lipstick-jolla-home-cancel_nfc_dialog")
                              : //% "Ok"
                                qsTrId("lipstick-jolla-home-acknowledge_nfc_dialog")
                        onClicked: closeFully()
                    }

                    SystemDialogTextButton {
                        id: openUrlButton
                        visible: isUri
                        width: header.width/2
                        height: parent.height
                        //% "Open URL"
                        text: qsTrId("lipstick-jolla-home-open_link_nfc_dialog")
                        onClicked: {
                            Qt.openUrlExternally(root.content)
                            closeFully()
                        }
                    }
                }
            }
        }
    }

    function closeFully() {
        root.shouldBeVisible = false
    }

    Connections {
        target: Lipstick.compositor
        onDisplayOff: closeFully()
        onDisplayOn: closeFully()
    }

    Item {
        id: fakeApplicationWindow
        // suppresses warnings by context menu
        property int _dimScreen
    }
}
