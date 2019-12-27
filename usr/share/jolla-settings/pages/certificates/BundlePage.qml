/*
* Copyright (c) 2016 - 2019 Jolla Ltd.
* Copyright (c) 2019 Open Mobile Platform LLC.
*
* License: Proprietary
*/

import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.settings.system 1.0
import org.nemomobile.models 1.0
import org.nemomobile.systemsettings 1.0

Page {
    id: root

    property string title
    property alias model: searchModel.sourceModel

    function showCertificate(details) {
        pageStack.animatorPush("com.jolla.settings.system.CertificateDetailsPage", { 'details': details })
    }

    SearchModel {
        id: searchModel
        searchRoles: [ 'commonName', 'countryName', 'organizationName', 'organizationalUnitName' ]
        caseSensitivity: Qt.CaseInsensitive
    }

    SilicaListView {
        anchors.fill: parent

        header: Column {
            width: parent.width

            PageHeader {
                title: root.title
            }

            SearchField {
                id: searchField
                width: parent.width
                onTextChanged: searchModel.pattern = text
            }
        }

        model: searchModel
        currentIndex: -1 // otherwise currentItem will steal focus

        section.property: 'primaryName'
        section.criteria: ViewSection.FirstCharacter
        section.delegate: SectionHeader { text: section; font.capitalization: Font.AllUppercase }

        delegate: BackgroundItem {
            id: delegateItem
            width: ListView.view.width
            height: column.height + Theme.paddingMedium*2

            /* Note: currently disabled, as they break the positioning of the listview header
            ListView.onAdd: AddAnimation {
                target: delegateItem
            }
            ListView.onRemove: RemoveAnimation {
                target: delegateItem
            }
            */

            Column {
                id: column

                x: Theme.horizontalPageMargin
                width: parent.width - x*2
                y: Theme.paddingMedium

                Label {
                    width: parent.width
                    text: primaryName
                    truncationMode: TruncationMode.Fade
                    color: delegateItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                }
                Label {
                    width: parent.width
                    text: secondaryName
                    truncationMode: TruncationMode.Fade
                    font.pixelSize: Theme.fontSizeSmall
                    color: delegateItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                }
            }

            onClicked: root.showCertificate(details)
        }

        VerticalScrollDecorator {}
    }
}
