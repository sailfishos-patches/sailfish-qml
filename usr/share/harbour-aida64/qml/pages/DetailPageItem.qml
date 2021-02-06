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
        id: listView_PageDetail
        model: lvModel
        anchors.fill: parent
        header: PageHeader {
            title: if (tabletLayout) return APP_NAME
                   else              return APP_NAME + " / " + infopageloader.getPageTitle(page_id) + lcs.emptyString
        }

//        Component.onCompleted: infopage.populatePage(page_id, listView_PageDetail)

        Timer {
            id: refreshTimer
            interval: 1000
            running: applicationActive
            repeat: page_id === InfoPageLoader.PAGEENUM_SYSTEM ||
                    page_id === InfoPageLoader.PAGEENUM_CPU ||
                    page_id === InfoPageLoader.PAGEENUM_DISPLAY ||
                    page_id === InfoPageLoader.PAGEENUM_BATTERY ||
                    page_id === InfoPageLoader.PAGEENUM_SAILFISH ||
                    page_id === InfoPageLoader.PAGEENUM_DEVICES ||
                    page_id === InfoPageLoader.PAGEENUM_THERMAL
            triggeredOnStart: true
            onTriggered: infopageloader.refreshPage(page_id, listView_PageDetail.model, settings.tempUnit)
        }

        delegate: ListItem {
            id: delegate
            contentHeight: listCol.height

            property int itemId: id

            enabled: page_id === InfoPageLoader.PAGEENUM_SYSFILES ||
                     page_id === InfoPageLoader.PAGEENUM_ABOUT

            Column {
                id: listCol
                x: horizPageMargin
                width: parent.width - 2 * x
                spacing: 0

                Row {
                    id: listRow
                    width: parent.width
                    spacing: Theme.paddingSmall
                    visible: page_id !== InfoPageLoader.PAGEENUM_ABOUT &&
                             itemId !== InfoPageLoader.IIDENUM_OGLES_EXT

                    Label {
                        id: fieldLabel
                        width: {
                            if (itemId === InfoPageLoader.IIDENUM_DIV_DEVICE ||
                                itemId === InfoPageLoader.IIDENUM_DIV_DEVICE_1ST ||
                                itemId === InfoPageLoader.IIDENUM_NO_SENSOR) return parent.width
                            else return parent.width * 0.5
                        }
                        text: field + lcs.emptyString
                        horizontalAlignment: Text.AlignRight
                        color: {
                            if (itemId === InfoPageLoader.IIDENUM_DIV_DEVICE ||
                                itemId === InfoPageLoader.IIDENUM_DIV_DEVICE_1ST ||
                                itemId === InfoPageLoader.IIDENUM_NO_SENSOR) return Theme.highlightColor
                            else return Theme.primaryColor
                        }
                        font.pixelSize: Theme.fontSizeSmall
                        wrapMode: Text.Wrap
                    }

                    Label {
                        id: valueLabel
                        width: {
                            if (itemId === InfoPageLoader.IIDENUM_DIV_DEVICE ||
                                itemId === InfoPageLoader.IIDENUM_DIV_DEVICE_1ST ||
                                itemId === InfoPageLoader.IIDENUM_NO_SENSOR) return 0
                            else return parent.width * 0.5
                        }
                        text: value + lcs.emptyString
                        color: Theme.highlightColor
                        font.pixelSize: Theme.fontSizeSmall
                        wrapMode: Text.Wrap
                    }
                }

                Label {
                    id: aboutFieldLabel
                    width: {
                        if (page_id === InfoPageLoader.PAGEENUM_ABOUT &&
                            Screen.sizeCategory >= Screen.Large) return parent.width * 0.7
                        else parent.width
                    }
                    visible: !listRow.visible
                    text: field + lcs.emptyString
                    color: {
                        if (itemId === InfoPageLoader.IIDENUM_OGLES_EXT) return Theme.highlightColor
                        else return Theme.primaryColor
                    }
                    horizontalAlignment: {
                        if (itemId === InfoPageLoader.IIDENUM_OGLES_EXT) return Text.AlignRight
                        else return Text.AlignHCenter
                    }
                    anchors.horizontalCenter: listCol.horizontalCenter
                    font.pixelSize: Theme.fontSizeSmall
                    wrapMode: Text.Wrap
                }

                Label {
                    id: aboutValueLabel
                    width: aboutFieldLabel.width
                    visible: aboutFieldLabel.visible
                    text: value + lcs.emptyString
                    color: {
                        if (itemId === InfoPageLoader.IIDENUM_OGLES_EXT) return Theme.primaryColor
                        else return Theme.highlightColor
                    }
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: listCol.horizontalCenter
                    font.pixelSize: Theme.fontSizeSmall
                    wrapMode: Text.Wrap
                }

                Item {
                    height: {
                        if (page_id === InfoPageLoader.PAGEENUM_ABOUT) return Theme.paddingLarge * 1.5
                        else return Theme.paddingSmall
                    }
                    width: 1
                }

                DockedPanel {
                     id: copiedPanel
                     width: parent.width
                     height: copiedLabel.height + 2 * copiedLabel.y
                     dock: Dock.Top

                     Label {
                         id: copiedLabel
                         color: Theme.primaryColor
                         horizontalAlignment: Text.Center
                         font.pixelSize: Theme.fontSizeSmall
                         x: horizPageMargin
                         y: Theme.paddingLarge
                         width: parent.width - 2 * x
                         wrapMode: Text.Wrap
                     }
                }
            }

            MouseArea {
                anchors.fill: parent

                onClicked: {
                    if (page_id === InfoPageLoader.PAGEENUM_SYSFILES)
                        pageStack.push(Qt.resolvedUrl("SysFilesPage.qml"), {sysfile_name:value})
                    else
                    if (page_id === InfoPageLoader.PAGEENUM_ABOUT) infopageloader.onClickHandler(itemId)
                }

                onPressAndHold: {
                    if (page_id !== InfoPageLoader.PAGEENUM_SYSFILES &&
                        page_id !== InfoPageLoader.PAGEENUM_ABOUT &&
                        value.length > 0) {
                        clipboard.setClipboard(value)
                        copiedLabel.text = qsTrId("copied_to_clipboard").replace("%s", "%1").arg("\"" + value + "\"") + lcs.emptyString
                        copiedPanel.visible = true
                        copiedTimer.running = true
                    }
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
