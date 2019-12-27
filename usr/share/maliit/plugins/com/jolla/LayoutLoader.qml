// Copyright (C) 2013 Jolla Ltd.
// Contact: Pekka Vuorela <pekka.vuorela@jollamobile.com>

import QtQuick 2.0

Loader {
    property int index: -1
    property var layoutModelItem: index >= 0 ? canvas.layoutModel.get(index) : null
    readonly property string sourceDirectory: "/usr/share/maliit/plugins/com/jolla/layouts/"

    width: parent.width
    source: !!layoutModelItem ? (sourceDirectory + layoutModelItem.layout) : ""
    onVisibleChanged: if (item) item.visible = visible
    asynchronous: true
    states: [
        State {
            name: "loaded"
            when: !!layoutModelItem && (status === Loader.Ready)

            PropertyChanges {
                target: item
                layoutIndex: index
                languageCode: layoutModelItem.languageCode
                type: layoutModelItem.type !== "" ? layoutModelItem.type : item.type
            }
        }
    ]
}
