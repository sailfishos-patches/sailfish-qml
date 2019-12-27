import QtQuick 2.0

Item {
    property var model
    property bool populated
    property int limit: 1

    property bool _loadStarted

    Connections {
        target: model
        onLoadingChanged: {
            if (model.loading) {
                _loadStarted = true
            } else if (_loadStarted) {
                // consider populated at this state even if model count was still zero
                populated = true
            }
        }

        onCountChanged: {
            if (model.count >= limit) {
                populated = true
            }
        }
    }
}
