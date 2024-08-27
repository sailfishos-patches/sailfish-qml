/*
 * Copyright (c) 2013 - 2019 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.6
import Sailfish.Accounts 1.0
import Sailfish.Silica 1.0
import com.jolla.gallery 1.0
import com.jolla.gallery.facebook 1.0
import org.nemomobile.socialcache 1.0

MediaSource {
    id: root

    //: Label of the Facebook album in Jolla Gallery application
    //% "Facebook"
    title: qsTrId("jolla_gallery_facebook-user_photos")
    icon: StandardPaths.resolveImport("com.jolla.gallery.facebook.FacebookGalleryIcon")
    model: allPhotos
    ready: syncHelper.syncProfiles.length > 0 && accountManager.cloudServiceReady

    property bool applicationActive: Qt.application.active

    property FacebookImageCacheModel allPhotos: FacebookImageCacheModel {
        type: FacebookImageCacheModel.Images
        nodeIdentifier: ""
        downloader: FacebookImageDownloader
    }

    property FacebookImageCacheModel fbUsers: FacebookImageCacheModel {
        type: FacebookImageCacheModel.Users
        onCountChanged: {
            root.page = count < 2 ? StandardPaths.resolveImport("com.jolla.gallery.facebook.AlbumsPage")
                                  : StandardPaths.resolveImport("com.jolla.gallery.facebook.UsersPage")
        }
        onModelUpdated: root.count = count > 0 ? getField(0, FacebookImageCacheModel.Count) : 0
    }

    property AccountManager accountManager: AccountManager {
        property bool cloudServiceReady

        Component.onCompleted: {
            cloudServiceReady = enabledAccounts("facebook", "facebook-images").length > 0
        }
    }

    property SyncHelper syncHelper: SyncHelper {
        socialNetwork: SocialSync.Facebook
        dataType: SocialSync.Images
        onLoadingChanged: {
            if (!loading) {
                fbUsers.refresh()
                allPhotos.refresh()
            }
        }
        onProfileDeleted: {
            fbUsers.refresh()
            allPhotos.refresh()
        }
    }

    // TODO: add a way to refresh the albums

    Component.onCompleted: {
        fbUsers.refresh()
        allPhotos.refresh()
    }
}
