/*
 * Copyright (c) 2012 - 2019 Jolla Ltd.
 * Copyright (c) 2019 Open Mobile Platform LLC.
 *
 * License: Proprietary
*/
import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0 as SilicaPrivate
import Sailfish.Contacts 1.0
import org.nemomobile.contacts 1.0

Column {
    id: root

    property string fieldAdditionText
    property url fieldAdditionIcon
    property int inputMethodHints: Qt.ImhNone
    property bool acceptMouseClicks
    property alias detailEditors: detailsRepeater
    property alias fieldDelegate: detailsRepeater.delegate

    property ContactDetailSuggestions suggestions

    property Person contact
    property var peopleModel
    property ListModel detailModel: DetailModel {}
    property int animationDuration: 350 // Same as button animation in AddFieldButton
    property bool populated
    property bool hasContent: testHasContent()

    readonly property bool ready: populated && _page && _page.status === PageStatus.Active

    readonly property Page _page: {
        var parentItem = root.parent
        while (parentItem) {
            if (parentItem.hasOwnProperty('__silica_page')) {
                return parentItem
            }
            parentItem = parentItem.parent
        }
        return null
    }

    function focusFieldAt(detailIndex, delayInterval) {
        if (detailIndex < detailsRepeater.count
                && detailsRepeater.itemAt(detailIndex).forceActiveFocus(delayInterval)) {
            return true
        }
        return false
    }

    function animateAndRemove(detailIndex, item, customAnimationDuration) {
        if (detailIndex < 0 || detailIndex >= detailModel.count || !item) {
            console.log("invalid index or item:", detailIndex, item)
            return false
        }

        if (detailIndex === detailModel.count - 1 && !detailEditors.itemAt(detailIndex).buttonMode) {
            // This is the last field remaining, so don't remove it.
            focus = true    // ensure vkb is closed
            detailModel.setProperty(detailIndex, "value", detailModel.emptyValue)
            return false
        }

        if (!!removalHeightAnimation.target) {
            // Just remove immediately instead of clashing with a current animation.
            detailModel.remove(detailIndex)
        } else {
            if (customAnimationDuration !== undefined) {
                removalHeightAnimation.duration = customAnimationDuration
            }
            removalHeightAnimation.target = item
            delayedRemove.detailIndex = detailIndex
            removalAnimation.start()
        }
        return true
    }

    function testHasContent(listModel) {
        listModel = listModel || detailModel
        for (var i = 0; i < listModel.count; ++i) {
            if (listModel.get(i).value.length > 0) {
                return true
            }
        }
        return false
    }

    width: parent.width

    ParallelAnimation {
        id: removalAnimation

        NumberAnimation {
            id: removalHeightAnimation
            property: "height"
            duration: root.animationDuration
            to: 0
            easing.type: Easing.InOutQuad
        }

        FadeAnimation {
            target: removalHeightAnimation.target
            duration: removalHeightAnimation.duration/2
            to: 0
        }

        onStopped: {
            // Remove the detail in the next event loop.
            delayedRemove.start()
        }
    }

    Timer {
        id: delayedRemove

        property int detailIndex: -1

        interval: 0
        onTriggered: {
            var item = detailsRepeater.itemAt(detailIndex)
            if (!!item && item === removalHeightAnimation.target) {
                removalHeightAnimation.target = null
                root.detailModel.remove(detailIndex)
            }
        }
    }

    Repeater {
        id: detailsRepeater
        model: detailModel
    }

}
