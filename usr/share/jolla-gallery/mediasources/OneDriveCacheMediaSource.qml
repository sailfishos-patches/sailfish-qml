import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.gallery 1.0
import com.jolla.gallery.onedrive 1.0
import org.nemomobile.socialcache 1.0
import com.jolla.gallery.extensions 1.0

MediaSource {
    id: root

    //: Label of the OneDrive album in Jolla Gallery application
    //% "OneDrive"
    title: qsTrId("jolla_gallery_onedrive-user_photos")
    icon: "/usr/lib/qt5/qml/com/jolla/gallery/onedrive/OneDriveGalleryIcon.qml"
    model: allPhotos
    count: model.count
    ready: false

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
            root.page = count < 2 ? "/usr/lib/qt5/qml/com/jolla/gallery/onedrive/OneDriveAlbumsPage.qml"
                                  : "/usr/lib/qt5/qml/com/jolla/gallery/onedrive/OneDriveUsersPage.qml"
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
        onSyncProfilesChanged: {
            root.ready = syncProfiles.length > 0
        }
    }

    property Item connections: Item {
        KeyProviderHelper { id: keyProviderHelper }
        Connections {
             target: root.accessTokensProvider
             onAccessTokenRetrieved: {
                 OneDriveImageDownloader.accessTokenRetrived(accessToken, accountId)
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
