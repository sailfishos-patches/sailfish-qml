/*
 * Copyright (c) 2015 – 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Email 0.1

Page {
    property EmailMessageListModel searchModel

    SilicaListView {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width

            PageHeader {
                //% "Search options"
                title: qsTrId("jolla-email-he-search_options")
            }

            ComboBox {
                id: searchInCombo

                currentIndex: searchModel.searchOn === EmailMessageListModel.LocalAndRemote ? 0 : searchModel.searchOn === EmailMessageListModel.Local ? 1 : 2
                //% "Search on"
                label: qsTrId("jolla-email-la-search_on")
                menu: ContextMenu {
                    MenuItem {
                        //: Search on server and device
                        //% "Server and device"
                        text: qsTrId("jolla-email-me_search_server_and_device")
                        onClicked: searchModel.searchOn = EmailMessageListModel.LocalAndRemote
                    }
                    MenuItem {
                        //: Search on device
                        //% "Device"
                        text: qsTrId("jolla-email-me_search_device")
                        onClicked: searchModel.searchOn = EmailMessageListModel.Local
                    }
                    MenuItem {
                        //: Search on server
                        //% "Server"
                        text: qsTrId("jolla-email-me_search_server")
                        onClicked: searchModel.searchOn = EmailMessageListModel.Remote
                    }
                }
            }

            SectionHeader {
                visible: searchInCombo.currentIndex === 1
                //% "Search in"
                text: qsTrId("jolla-email-la-search_in")
            }

            TextSwitch {
                visible: searchInCombo.currentIndex === 1
                //: Search From address, the email sender
                //% "From"
                text: qsTrId("jolla-email-la-search_from")
                checked: searchModel.searchFrom
                onCheckedChanged: searchModel.searchFrom = checked
            }

            TextSwitch {
                visible: searchInCombo.currentIndex === 1
                //: Search recipients addresses, the recipients of the email
                //% "Recipients"
                text: qsTrId("jolla-email-la-search_recipients")
                checked: searchModel.searchRecipients
                onCheckedChanged: searchModel.searchRecipients = checked
            }

            TextSwitch {
                visible: searchInCombo.currentIndex === 1
                //: Search the email subject
                //% "Subject"
                text: qsTrId("jolla-email-la-search_subject")
                checked: searchModel.searchSubject
                onCheckedChanged: searchModel.searchSubject = checked
            }

            TextSwitch {
                visible: searchInCombo.currentIndex === 1
                //: Search email body, the email content
                //% "Message body"
                text: qsTrId("jolla-email-la-search_body")
                checked: searchModel.searchBody
                onCheckedChanged: searchModel.searchBody = checked
            }
        }
        VerticalScrollDecorator {}
    }
}
