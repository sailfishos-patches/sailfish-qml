import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.aida64.infopageloader 1.0

Item {
    property int page_id
    property int tabletLayout
    property var lvModel: infopageloader.loadPage(page_id, settings.getTempUnit + lcs.emptyString)

    TextEdit {
        id: clipboard
        visible: false
        function setClipboard(value) {
             text = value
             selectAll()
             copy()
         }
         function getClipboard() {
             text = ""
             paste()
             return text
         }
    }

    SilicaListView {
        id: listView_Apps
        model: lvModel
        anchors.fill: parent
        header: PageHeader {
            title: if (tabletLayout) return APP_NAME
                   else              return APP_NAME + " / " + infopageloader.getPageTitle(page_id) + lcs.emptyString
        }

        delegate: ListItem {
            id: delegate
            contentHeight: listCol.height
            enabled: false

            property int itemId: id

            Column {
                id: listCol
                x: horizPageMargin
                width: parent.width - 2 * x
                spacing: 0

                Item {
                  height: Theme.paddingSmall
                  width: 1
                  visible: itemId === InfoPageLoader.IIDENUM_APP
                }

                Row {
                    id: listRow
                    width: listCol.width
                    spacing: Theme.paddingMedium

                    Image {
                        id: listIcon
                        source: icon
                        width: 86
                        height: 86
                        visible: itemId === InfoPageLoader.IIDENUM_APP
                        anchors.verticalCenter: listRow.verticalCenter
                    }

                    Column {
                        id: listCol2
                        anchors.verticalCenter: listRow.verticalCenter
                        width: {
                            if (itemId === InfoPageLoader.IIDENUM_APP)
                                return listRow.width - listIcon.width - Theme.paddingMedium
                            else return listRow.width;
                        }

                        Label {
                            id: fieldLabel
                            width: listCol2.width
                            text: field + lcs.emptyString
                            color: {
                                if (itemId === InfoPageLoader.IIDENUM_DIV_DEVICE ||
                                    itemId === InfoPageLoader.IIDENUM_DIV_DEVICE_1ST ||
                                    itemId === InfoPageLoader.IIDENUM_NO_SENSOR) return Theme.highlightColor
                                else return Theme.primaryColor
                            }
                            horizontalAlignment: {
                                if (itemId === InfoPageLoader.IIDENUM_DIV_DEVICE ||
                                    itemId === InfoPageLoader.IIDENUM_DIV_DEVICE_1ST ||
                                    itemId === InfoPageLoader.IIDENUM_NO_SENSOR) return Text.AlignRight
                                else return Text.AlignLeft
                            }
                            font.pixelSize: Theme.fontSizeSmall
                            wrapMode: Text.Wrap
                        }

                        Label {
                            id: valueLabel
                            width: listCol2.width
                            text: value + lcs.emptyString
                            color: Theme.highlightColor
                            font.pixelSize: Theme.fontSizeSmall
                            wrapMode: Text.Wrap
                            visible: itemId === InfoPageLoader.IIDENUM_APP
                        }
                    }
                }

                Item {
                  height: Theme.paddingSmall
                  width: 1
                }

                DockedPanel {
                     id: copiedPanel
                     width: parent.width
                     height: copiedCol.height
                     contentHeight: height
                     dock: Dock.Top

                     Column {
                         id: copiedCol
                         x: horizPageMargin
                         width: parent.width - 2 * x

                         Item {
                             height: Theme.paddingLarge
                             width: 1
                         }

                         Label {
                             id: copiedLabel
                             color: Theme.primaryColor
                             horizontalAlignment: Text.Center
                             verticalAlignment: Text.Center
                             font.pixelSize: Theme.fontSizeSmall
                             width: parent.width
                             wrapMode: Text.Wrap
                         }

                         Item {
                             height: Theme.paddingLarge
                             width: 1
                         }

                     }
                }
            }

            MouseArea {
                anchors.fill: parent

                onPressAndHold: {
                    clipboard.setClipboard(value);
                    copiedLabel.text = qsTrId("copied_to_clipboard").replace("%s", "%1").arg("\"" + value + "\"") + lcs.emptyString
                    copiedPanel.visible = true;
                    copiedTimer.running = true;
                }

                Timer {
                    id: copiedTimer
                    interval: 2000
                    running: false
                    repeat: false
                    triggeredOnStart: false
                    onTriggered: copiedPanel.visible = false
                }
            }
        }

        VerticalScrollDecorator {}
    }
}
