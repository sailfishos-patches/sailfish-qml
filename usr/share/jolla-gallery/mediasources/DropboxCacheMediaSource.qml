import QtQuick 2.0
import com.jolla.gallery 1.0
import com.jolla.gallery.dropbox 1.0
import org.nemomobile.socialcache 1.0

MediaSource {
    id: root

    //: Label of the Dropbox album in Jolla Gallery application
    //% "Dropbox"
    title: qsTrId("jolla_gallery_dropbox-user_photos")
    icon: "/usr/lib/qt5/qml/com/jolla/gallery/dropbox/DropboxGalleryIcon.qml"
    model: allPhotos
    count: model.count
    ready: false

    property bool applicationActive: Qt.application.active

    property DropboxImageCacheModel allPhotos: DropboxImageCacheModel {
        type: DropboxImageCacheModel.Images
        nodeIdentifier: "" //constructNodeIdentifier("", "", "", "")
        downloader: DropboxImageDownloader
    }

    property DropboxImageCacheModel dropboxUsers: DropboxImageCacheModel {
        type: DropboxImageCacheModel.Users
        onCountChanged: {
            root.page = count < 2 ? "/usr/lib/qt5/qml/com/jolla/gallery/dropbox/DropboxAlbumsPage.qml"
                                  : "/usr/lib/qt5/qml/com/jolla/gallery/dropbox/DropboxUsersPage.qml"
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
        onSyncProfilesChanged: {
            root.ready = syncProfiles.length > 0
        }
    }

    // TODO: add a way to refresh the albums

    Component.onCompleted: {
        dropboxUsers.refresh()
        allPhotos.refresh()
    }
}
