/****************************************************************************
**
** Copyright (C) 2013-2016 Jolla Ltd.
** Contact: Raine Mäkeläinen <raine.makelainen@jollamobile.com>
**
****************************************************************************/

import QtQuick 2.0
import QtDocGallery 5.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0 as Private
import "private"

PickerDialog {
    id: documentPickerDialog

    property alias _contentModel: documentModel

    //: Placeholder text of document search field in content picker
    //% "Search documents"
    property string _headerPlaceholderText: qsTrId("components_pickers-ph-search_documents")

    //: Empty state text if no documents available. This should be positive and inspiring for the user.
    //% "Copy some documents to device"
    property string _emptyPlaceholderText: qsTrId("components_pickers-la-no-documents-on-device")

    property alias _contentType: documentModel.contentType

    orientationTransitions: Private.PageOrientationTransition {
        fadeTarget: _background ? listView : __silica_applicationwindow_instance.contentItem
        targetPage: documentPickerDialog
    }

    SilicaListView {
        id: listView

        property bool searchActive

        currentIndex: -1
        anchors.fill: parent
        header: SearchDialogHeader {
            width: listView.width
            dialog: documentPickerDialog
            placeholderText: _headerPlaceholderText
            model: documentModel
            contentType: _contentType
            visible: active || documentModel.count > 0
            selectedCount: _selectedCount
            showBack: !_clearOnBackstep
            _glassOnly: documentPickerDialog._background

            onActiveFocusChanged: {
                if (activeFocus) {
                    listView.currentIndex = -1
                }
            }

            onActiveChanged: listView.searchActive = active
        }

        model: documentModel.model

        ViewPlaceholder {
            text: _emptyPlaceholderText
            enabled: !listView.searchActive && documentModel.count === 0 && (documentModel.status === DocumentGalleryModel.Finished || documentModel.status === DocumentGalleryModel.Idle)
        }

        DocumentModel {
            id: documentModel
            selectedModel: _selectedModel
        }

        delegate: FileBackgroundItem {
            id: documentItem

            baseName: Theme.highlightText(documentModel.baseName(model.fileName), documentModel.filter, Theme.highlightColor)
            extension: Theme.highlightText(documentModel.extension(model.fileName), documentModel.filter, Theme.highlightColor)
            mimeType: model.mimeType
            size: model.fileSize
            modified: model.lastModified
            selected: model.selected
            textFormat: Text.StyledText

            ListView.onAdd: AddAnimation { target: documentItem; duration: _animationDuration }
            ListView.onRemove: RemoveAnimation { target: documentItem; duration: _animationDuration }

            onClicked: documentModel.updateSelected(index, !selected)
        }

        VerticalScrollDecorator {}
    }
}
