import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.dbus 2.0
import org.coderus.searchengines 1.0

Page {
    id: page

    allowedOrientations: Orientation.All

    DBusInterface {
        id: settingsDBus
        service: "com.jolla.settings"
        path: "/com/jolla/settings/ui"
        iface: "com.jolla.settings.ui"

        function openBrowserSettings() {
            call("showPage", ["applications/sailfish-browser.desktop"])
        }
    }

    function getEngine(title, hostname, searchEngine) {
        if (searchEngine.indexOf("//") === 0) {
            var newhost = "http:" + searchEngine
        } else if (searchEngine.indexOf("/") === 0) {
            newhost = hostname + searchEngine
        } else {
            newhost = searchEngine
        }

        console.log("##", title, hostname, searchEngine, newhost)

        var request = new XMLHttpRequest();
        request.onreadystatechange = function() {
            if (request.status && request.status != 200 && request.status != 301) {
                if (pageStack.depth > 1) {
                    pageStack.pop()
                }
                return
            }
            if (!request.readyState || request.readyState !== XMLHttpRequest.DONE) {
                return
            }

            searchEnginesModel.add(title, request.responseText)
            if (pageStack.depth > 1) {
                pageStack.pop()
            }
        }

        request.open("GET", newhost);
        request.send();
    }

    SilicaListView {
        id: listView
        model: SearchEnginesModel {
            id: searchEnginesModel
        }

        PullDownMenu {
            MenuItem {
                text: qsTr("Open Browser settings")
                onClicked: settingsDBus.openBrowserSettings()
            }
        }

        anchors.fill: parent
        header: PageHeader {
            title: qsTr("Search engines")
        }
        delegate: ListItem {
            id: delegate
            contentHeight: Theme.itemSizeSmall
            menu: ContextMenu {
                MenuItem {
                    text: qsTr("Remove")
                    onClicked: {
                        delegate.remorseAction(qsTr("Remove %1".arg(title)), function (){
                            console.log("removing", title, filename)
                            searchEnginesModel.remove(filename)
                        })
                    }
                }
            }

            Label {
                anchors.left: parent.left
                anchors.leftMargin: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                text: title
                color: delegate.highlighted ? Theme.highlightColor : Theme.primaryColor
            }
        }
        footer: BackgroundItem {
            id: addFooter
            height: Theme.itemSizeSmall
            Image {
                id: addImage

                x: Theme.horizontalPageMargin
                source: "image://theme/icon-m-add" + (addFooter.highlighted ? "?" + Theme.highlightColor : "")
                anchors.verticalCenter: parent.verticalCenter
            }

            Label {
                anchors.left: addImage.right
                anchors.leftMargin: Theme.paddingLarge
                text: qsTr("Add search engine")
                anchors.verticalCenter: parent.verticalCenter
                color: addFooter.highlighted ? Theme.highlightColor : Theme.primaryColor
            }
            onClicked: {
                var page = pageStack.push(Qt.resolvedUrl("SecondPage.qml"))
                page.selected.connect(getEngine)
            }
        }

        VerticalScrollDecorator {}
    }
}
