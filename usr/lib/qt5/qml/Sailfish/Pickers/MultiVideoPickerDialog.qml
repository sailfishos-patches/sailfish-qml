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
import Sailfish.Gallery 1.0
import Sailfish.Pickers 1.0
import "private"

PickerDialog {
    id: videoPickerDialog

    Formatter {
        id: formatter
    }

    orientationTransitions: Private.PageOrientationTransition {
        fadeTarget: _background ? gridView : __silica_applicationwindow_instance.contentItem
        targetPage: videoPickerDialog
    }

    ImageGridView {
        id: gridView

        property bool searchActive

        anchors.fill: parent
        // reference column width: 960 / 4
        columnCount: Math.floor(width / (Theme.pixelRatio * 240))
        dateProperty: "lastModified"

        header: SearchDialogHeader {
            width: gridView.width
            dialog: videoPickerDialog
            //: Videos search field placeholder text
            //% "Search videos"
            placeholderText: qsTrId("components_pickers-ph-search_videos")
            model: videoModel
            contentType: ContentType.Video
            visible: active || videoModel.count > 0
            selectedCount: _selectedCount
            showBack: !_clearOnBackstep
            _glassOnly: videoPickerDialog._background

            onActiveFocusChanged: {
                if (activeFocus) {
                    gridView.currentIndex = -1
                }
            }

            onActiveChanged: gridView.searchActive = active
        }

        model: videoModel.model

        VideoModel {
            id: videoModel
            selectedModel: _selectedModel
        }

        ViewPlaceholder {
            //: Empty state text if no videos available. This should be positive and inspiring for the user.
            //% "Copy some videos to device"
            text: qsTrId("components_pickers-la-no-videos-on-device")
            enabled: !gridView.searchActive && videoModel.count === 0 && (videoModel.status === DocumentGalleryModel.Finished || videoModel.status === DocumentGalleryModel.Idle)
        }

        delegate: ThumbnailVideo {
            id: thumbnail
            source: model.url
            size: gridView.cellWidth
            mimeType: model.mimeType
            duration: model.duration > 3600 ? formatter.formatDuration(model.duration, Formatter.DurationLong) :
                                              formatter.formatDuration(model.duration, Formatter.DurationShort)
            title: model.title
            selected: model.selected
            GridView.onAdd: AddAnimation { target: thumbnail; duration: _animationDuration }
            GridView.onRemove: RemoveAnimation { target: thumbnail; duration: _animationDuration }
            onClicked: videoModel.updateSelected(index, !selected)
        }
    }
}
