import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0

Item {
    property int contactCount: allContactsModel.populated ? allContactsModel.count : 0
    property int favoriteCount: favoritesModel.populated ? favoritesModel.count : 0

    anchors.fill: parent

    Column {
        id: favoritesColumn

        anchors.fill: parent
        anchors.topMargin: placeholder.icon.y + placeholder.icon.height + Theme.paddingLarge

        Repeater {
            id: favoritesRepeater

            model: favoritesModel
            delegate: CoverContact {
                visible: index < 2
                height: favoritesColumn.height / 2
                width: favoritesColumn.width
                contact: {
                    "primaryName" : model.primaryName,
                    "secondaryName" : model.secondaryName,
                    "avatarUrl" : model.avatarUrl,
                    "displayLabel" : model.displayLabel,
                    "presenceState": model.globalPresenceState
                }
                center: true
            }
        }
    }

    function getText(favorites, contacts) {
        if (favorites === 0) {
            if (contacts > 0) {
                //: Cover header when no favorites
                //% "Add favorites"
                return qsTrId("contacts-he-add_favorites");
            } else {
                //: Cover header when no contacts
                //% "Add contacts"
                return qsTrId("contacts-he-add_contacts")
            }
        }
        return "";
    }

    // If there are no contacts or no favorites show placeholder with instructional text.
    // If there are 1-2 favorites show only the icon from the placeholder, favoritesColumn
    // will place content below the icon
    CoverPlaceholder {
        id: placeholder

        icon.source: "image://theme/icon-launcher-people"
        text: getText(favoriteCount, contactCount)
    }

    // No contacts: allow user to select "plus" to add contacts
    CoverActionList {
        enabled: contactCount == 0
        CoverAction {
            iconSource: "image://theme/icon-cover-new"
            onTriggered: {
                contactList.openNewContactEditor({}, PageStackAction.Immediate)
                app.activate()
            }
        }
    }

    CoverActionList {
        enabled: contactCount > 0
        CoverAction {
            iconSource: "image://theme/icon-cover-search"
            onTriggered: {
                app.openSearch()
            }
        }
    }
}
