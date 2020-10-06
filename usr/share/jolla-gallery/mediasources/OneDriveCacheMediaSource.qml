/*
 * Copyright (c) 2013 - 2019 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import com.jolla.gallery 1.0
import com.jolla.gallery.onedrive 1.0
import org.nemomobile.socialcache 1.0
import com.jolla.gallery.extensions 1.0

MediaSource {
    id: root

    //: Label of the OneDrive album in Jolla Gallery application
    //% "OneDrive"
    title: qsTrId("jolla_gallery_onedrive-user_photos")
    icon: StandardPaths.resolveImport("com.jolla.gallery.onedrive.OneDriveGalleryIcon")
    model: allPhotos
    count: model.count
    ready: syncHelper.syncProfiles.length > 0 && accountManager.cloudServiceReady

    property AccessTokensProvider accessTokensProvider: AccessTokensProvider {
        service: "onedrive-sync"
        clientId: keyProviderHelper.oneDriveClientId
    }

    property bool applicationActive: Qt.application.active

    property OneDriveImageCacheModel allPhotos: OneDriveImageCacheModel {
        type: OneDriveImageCacheModel.Images
        nodeIdentifier: ""
        downloader: OneDriveImageDownloader
    }

    property OneDriveImageCacheModel oneDriveUsers: OneDriveImageCacheModel {
        type: OneDriveImageCacheModel.Users
        onCountChanged: {
            root.page = count < 2 ? StandardPaths.resolveImport("com.jolla.gallery.onedrive.OneDriveAlbumsPage")
                                  : StandardPaths.resolveImport("com.jolla.gallery.onedrive.OneDriveUsersPage")
        }
    }

    property AccountManager accountManager: AccountManager {
        property bool cloudServiceReady

        Component.onCompleted: {
            cloudServiceReady = enabledAccounts("onedrive", "onedrive-images").length > 0
        }
    }

    property SyncHelper syncHelper: SyncHelper {
        socialNetwork: SocialSync.OneDrive
        dataType: SocialSync.Images
        onLoadingChanged: {
            if (!loading) {
                oneDriveUsers.refresh()
                allPhotos.refresh()
            }
        }
        onProfileDeleted: {
            oneDriveUsers.refresh()
            allPhotos.refresh()
        }
    }

    property Item connections: Item {
        KeyProviderHelper { id: keyProviderHelper }
        Connections {
             target: root.accessTokensProvider
             onAccessTokenRetrieved: {
                 OneDriveImageDownloader.accessTokenRetrieved(accessToken, accountId)
             }
         }

         Connections {
             target: OneDriveImageDownloader
             onAccessTokenRequested: {
                 root.accessTokensProvider.requestAccessToken(accountId)
             }
         }
    }

    Component.onCompleted: {
        OneDriveImageDownloader.optimalThumbnailSize = Theme.itemSizeExtraLarge
        oneDriveUsers.refresh()
        allPhotos.refresh()
    }
}
