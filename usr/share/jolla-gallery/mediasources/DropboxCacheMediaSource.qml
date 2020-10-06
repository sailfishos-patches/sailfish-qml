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
import com.jolla.gallery.dropbox 1.0
import org.nemomobile.socialcache 1.0

MediaSource {
    id: root

    //: Label of the Dropbox album in Jolla Gallery application
    //% "Dropbox"
    title: qsTrId("jolla_gallery_dropbox-user_photos")
    icon: StandardPaths.resolveImport("com.jolla.gallery.dropbox.DropboxGalleryIcon")
    model: allPhotos
    count: model.count
    ready: syncHelper.syncProfiles.length > 0 && accountManager.cloudServiceReady

    property bool applicationActive: Qt.application.active

    property DropboxImageCacheModel allPhotos: DropboxImageCacheModel {
        type: DropboxImageCacheModel.Images
        nodeIdentifier: "" //constructNodeIdentifier("", "", "", "")
        downloader: DropboxImageDownloader
    }

    property DropboxImageCacheModel dropboxUsers: DropboxImageCacheModel {
        type: DropboxImageCacheModel.Users
        onCountChanged: {
            root.page = count < 2 ? StandardPaths.resolveImport("com.jolla.gallery.dropbox.DropboxAlbumsPage")
                                  : StandardPaths.resolveImport("com.jolla.gallery.dropbox.DropboxUsersPage")
        }
    }

    property AccountManager accountManager: AccountManager {
        property bool cloudServiceReady

        Component.onCompleted: {
            cloudServiceReady = enabledAccounts("dropbox", "dropbox-images").length > 0
        }
    }

    property SyncHelper syncHelper: SyncHelper {
        socialNetwork: SocialSync.Dropbox
        dataType: SocialSync.Images
        onLoadingChanged: {
            if (!loading) {
                dropboxUsers.refresh()
                allPhotos.refresh()
            }
        }
        onProfileDeleted: {
            dropboxUsers.refresh()
            allPhotos.refresh()
        }
    }

    // TODO: add a way to refresh the albums

    Component.onCompleted: {
        dropboxUsers.refresh()
        allPhotos.refresh()
    }
}
