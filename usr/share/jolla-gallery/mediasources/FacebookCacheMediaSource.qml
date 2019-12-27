import QtQuick 2.0
import com.jolla.gallery 1.0
import com.jolla.gallery.facebook 1.0
import org.nemomobile.socialcache 1.0

MediaSource {
    id: root

    //: Label of the Facebook album in Jolla Gallery application
    //% "Facebook"
    title: qsTrId("jolla_gallery_facebook-user_photos")
    icon: "/usr/lib/qt5/qml/com/jolla/gallery/facebook/FacebookGalleryIcon.qml"
    model: allPhotos
    ready: false

    property bool applicationActive: Qt.application.active

    property FacebookImageCacheModel allPhotos: FacebookImageCacheModel {
        type: FacebookImageCacheModel.Images
        nodeIdentifier: ""
        downloader: FacebookImageDownloader
    }

    property FacebookImageCacheModel fbUsers: FacebookImageCacheModel {
        type: FacebookImageCacheModel.Users
        onCountChanged: {
            root.page = count < 2 ? "/usr/lib/qt5/qml/com/jolla/gallery/facebook/AlbumsPage.qml"
                                  : "/usr/lib/qt5/qml/com/jolla/gallery/facebook/UsersPage.qml"
        }
        onModelUpdated: root.count = count > 0 ? getField(0, FacebookImageCacheModel.Count) : 0
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
        onSyncProfilesChanged: {
            root.ready = syncProfiles.length > 0
        }
    }

    // TODO: add a way to refresh the albums

    Component.onCompleted: {
        fbUsers.refresh()
        allPhotos.refresh()
    }
}
