import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Contacts 1.0
import org.nemomobile.contacts 1.0
import "../pages/common/PageCache.js" as PageCache

CoverBackground {
    id: coverRoot

    property PeopleModel favoritesModel: PageCache.favoritesModel
    property PeopleModel allContactsModel: PageCache.allContactsModel
    property bool active: status === Cover.Active

    // 0 favorites/contacts: show placeholder with actions
    // 1-2 favorites show favorite names below placeholder icon
    // 3+ favorites animate favorite avatars
    Loader {
        anchors.fill: parent
        source: favoritesModel.count < 3 ? "SimpleCover.qml" : "AnimatingCover.qml"
    }
}

