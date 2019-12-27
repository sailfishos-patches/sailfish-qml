import QtQuick 2.0
import com.jolla.gallery 1.0
import com.jolla.gallery.vk 1.0
import org.nemomobile.socialcache 1.0

MediaSource {
    id: root

    //: Label of the VK album in Jolla Gallery application
    //% "VK"
    title: qsTrId("jolla_gallery_vk-user_photos")
    icon: "/usr/lib/qt5/qml/com/jolla/gallery/vk/VKGalleryIcon.qml"
    model: allPhotos
    count: model.count
    ready: false

    property bool applicationActive: Qt.application.active

    property VKImageCacheModel allPhotos: VKImageCacheModel {
        type: VKImageCacheModel.Images
        nodeIdentifier: constructNodeIdentifier("", "", "", "")
        downloader: VKImageDownloader
    }

    property VKImageCacheModel vkUsers: VKImageCacheModel {
        type: VKImageCacheModel.Users
        onCountChanged: {
            root.page = count < 2 ? "/usr/lib/qt5/qml/com/jolla/gallery/vk/VKAlbumsPage.qml"
                                  : "/usr/lib/qt5/qml/com/jolla/gallery/vk/VKUsersPage.qml"
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
        onSyncProfilesChanged: {
            root.ready = syncProfiles.length > 0
        }
    }

    // TODO: add a way to refresh the albums

    Component.onCompleted: {
        vkUsers.refresh()
        allPhotos.refresh()
    }
}
