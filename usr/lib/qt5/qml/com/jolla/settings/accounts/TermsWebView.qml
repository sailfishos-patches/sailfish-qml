import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.WebView 1.0
import Sailfish.WebEngine 1.0

Page {
    id: webPage

    property alias title: header.title
    property alias url: webView.url

    PageHeader {
        id: header
    }

    WebView {
        id: webView
        privateMode: true

        anchors {
            top: header.bottom
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }

        Component.onCompleted: {
            WebEngineSettings.popupEnabled = false
        }
    }
}

