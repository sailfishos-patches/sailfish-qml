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
import com.jolla.gallery.vk 1.0
import org.nemomobile.socialcache 1.0

MediaSource {
    id: root

    //: Label of the VK album in Jolla Gallery application
    //% "VK"
    title: qsTrId("jolla_gallery_vk-user_photos")
    icon: StandardPaths.resolveImport("com.jolla.gallery.vk.VKGalleryIcon")
    model: allPhotos
    count: model.count
    ready: syncHelper.syncProfiles.length > 0 && accountManager.cloudServiceReady

    property bool applicationActive: Qt.application.active

    property VKImageCacheModel allPhotos: VKImageCacheModel {
        type: VKImageCacheModel.Images
        nodeIdentifier: constructNodeIdentifier("", "", "", "")
        downloader: VKImageDownloader
    }

    property VKImageCacheModel vkUsers: VKImageCacheModel {
        type: VKImageCacheModel.Users
        onCountChanged: {
            root.page = count < 2 ? StandardPaths.resolveImport("com.jolla.gallery.vk.VKAlbumsPage")
                                  : StandardPaths.resolveImport("com.jolla.gallery.vk.VKUsersPage")
        }
    }

    property AccountManager accountManager: AccountManager {
        property bool cloudServiceReady

        Component.onCompleted: {
            cloudServiceReady = enabledAccounts("vk", "vk-images").length > 0
        }
    }

    property SyncHelper syncHelper: SyncHelper {
        socialNetwork: SocialSync.VK
        dataType: SocialSync.Images
        onLoadingChanged: {
            if (!loading) {
                vkUsers.refresh()
                allPhotos.refresh()
            }
        }
        onProfileDeleted: {
            vkUsers.refresh()
            allPhotos.refresh()
        }
    }

    // TODO: add a way to refresh the albums

    Component.onCompleted: {
        vkUsers.refresh()
        allPhotos.refresh()
    }
}
