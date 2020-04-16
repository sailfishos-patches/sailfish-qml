/****************************************************************************************
**
** Copyright (C) 2019 Open Mobile Platform LLC
** All rights reserved.
**
** License: Proprietary.
**
****************************************************************************************/

import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.gallery 1.0
import com.jolla.gallery.nextcloud 1.0
import com.jolla.gallery.extensions 1.0
import org.nemomobile.socialcache 1.0

MediaSource {
    id: root

    //: Label of the Nextcloud album in Jolla Gallery application
    //% "Nextcloud"
    title: qsTrId("jolla_gallery_nextcloud-la-user_photos")
    icon: "/usr/lib/qt5/qml/com/jolla/gallery/nextcloud/NextcloudGalleryIcon.qml"
    model: nextcloudUsers.count == 1
          ? nextcloudAlbums
          : nextcloudUsers
    count: photoCounter.count
    ready: nextcloudUsers.count > 0
    page: nextcloudUsers.count == 1
          ? "/usr/lib/qt5/qml/com/jolla/gallery/nextcloud/NextcloudAlbumsPage.qml"
          : "/usr/lib/qt5/qml/com/jolla/gallery/nextcloud/NextcloudUsersPage.qml"

    property bool applicationActive: Qt.application.active

    property NextcloudPhotoCounter photoCounter: NextcloudPhotoCounter {
        imageCache: NextcloudImageCache
    }

    property NextcloudUserModel nextcloudUsers: NextcloudUserModel {
        imageCache: NextcloudImageCache
    }

    property NextcloudAlbumModel nextcloudAlbums: NextcloudAlbumModel {
        imageCache: NextcloudImageCache
        accountId: nextcloudUsers.count > 0 ? nextcloudUsers.at(0).accountId : 0
        userId: nextcloudUsers.count > 0 ? nextcloudUsers.at(0).userId : ""
    }
}
