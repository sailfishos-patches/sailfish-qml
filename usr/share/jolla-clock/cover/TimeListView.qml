import QtQuick 2.0
import Sailfish.Silica 1.0

ListView {
    id: timeListView

    property int maximumCount
    property real itemHeight: Theme.itemSizeSmall/2
    property int visualCount: Math.min(count, maximumCount)

    property var layoutData: new Array
    property var paddingData

    function updateLayoutData(index, pre, time, post) {
        var ld = layoutData
        var data = ld[index]
        if (data === undefined)
            data = new Object
        data.pre = pre
        data.time = time
        data.post = post
        ld[index] = data
        layoutData = ld
    }

    clip: true
    visible: count > 0
    interactive: false
    model: alarmsModel
    width: parent.width
    height: itemHeight * visualCount
}
