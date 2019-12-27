import QtQuick 2.0
import Sailfish.Silica 1.0
import QtQuick.XmlListModel 2.0
import QtWebKit 3.0
import QtWebKit.experimental 1.0

Page {
    id: page

    // The effective value will be restricted by ApplicationWindow.allowedOrientations
    allowedOrientations: Orientation.All

    property bool downloadError: false

    signal selected(string title, string hostname, string searchEngine)

    Loader {
        id: webLoader
        property url loadUrl
        width: 0
        height: 0
        sourceComponent: Component {
            WebView {
                id: webView
                url: loadUrl
                experimental.preferences.navigatorQtObjectEnabled: true
                experimental.onMessageReceived: {
                    if (message.data) {
                        var oslink = JSON.parse(message.data)
                        oslink.location = webView.url
                        searchModel.append(oslink)
                    } else {
                        downloadError = true
                    }
                    webLoader.active = false
                }
                onLoadingChanged: {
                    if (loadRequest.status === WebView.LoadSucceededStatus) {
                        experimental.evaluateJavaScript("
var xpath = \"//link[@type='application/opensearchdescription+xml']\";
var elem = document.evaluate(xpath, document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue;
if (elem) {
    navigator.qt.postMessage(JSON.stringify({'title':elem.title, 'href':elem.href}));
} else {
    navigator.qt.postMessage('');
}
")
                        downloadBusy.visible = false
                    } else if (loadRequest.status === WebView.LoadFailedStatus) {
                        downloadBusy.visible = false
                        downloadError = true
                    }
                }
            }
        }
        active: false
    }

    function getOpensearch(title, host) {
        if (host.indexOf("http") !== 0) {
            var newhost = "http://" + host
        } else {
            newhost = host
        }

        selected(title, "", newhost)
    }

    function getEngine(host) {
        if (host.indexOf("http") !== 0) {
            var newhost = "https://" + host
        } else {
            newhost = host
        }

        searchModel.clear()
        downloadError = false

        webLoader.loadUrl = newhost
        webLoader.active = true
    }

    SilicaFlickable {
        anchors.fill: parent

        contentHeight: column.height

        Column {
            id: column

            width: page.width
            spacing: Theme.paddingLarge
            PageHeader {
                title: qsTr("Add search engine")
            }
            TextField {
                id: hostField
                width: parent.width
                placeholderText: qsTr("Search hostname")
                label: placeholderText
                focus: true
                inputMethodHints: Qt.ImhUrlCharactersOnly
                EnterKey.iconSource: "image://theme/icon-m-cloud-download"
                EnterKey.onClicked: {
                    if (downloadButton.enabled) {
                        downloadBusy.visible = true
                        getEngine(hostField.text)
                    }
                }
            }

            Button {
                id: downloadButton
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Get search engine")
                enabled: hostField.text && !downloadBusy.visible
                onClicked: {
                    downloadBusy.visible = true
                    getEngine(hostField.text)
                }
            }

            BusyIndicator {
                id: downloadBusy
                anchors.horizontalCenter: parent.horizontalCenter
                size: BusyIndicatorSize.Large
                running: visible
                visible: false
            }

            SectionHeader {
                text: qsTr("Available search engines")
                visible: searchModel.count > 0
            }

            Repeater {
                model: ListModel {
                    id: searchModel
                }
                delegate: BackgroundItem {
                    id: delegate

                    Label {
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.paddingLarge
                        text: title
                        anchors.verticalCenter: parent.verticalCenter
                        color: delegate.highlighted ? Theme.highlightColor : Theme.primaryColor
                    }

                    onClicked:  {
                        console.log("$$", title, href)
                        selected(title, location, href)
                        installingBusy.visible = true
                    }
                }
            }

            BusyIndicator {
                id: installingBusy
                anchors.horizontalCenter: parent.horizontalCenter
                size: BusyIndicatorSize.Large
                running: visible
                visible: false
            }

            TextField {
                id: opensearchTitle
                width: parent.width
                placeholderText: qsTr("Search engine title")
                label: placeholderText
                visible: downloadError
                EnterKey.iconSource: "image://theme/icon-m-next"
                EnterKey.onClicked: {
                    opensearchLink.forceActiveFocus()
                }
            }

            TextField {
                id: opensearchLink
                width: parent.width
                placeholderText: qsTr("Opensearch link")
                label: placeholderText
                visible: downloadError
                inputMethodHints: Qt.ImhUrlCharactersOnly
                EnterKey.iconSource: "image://theme/icon-m-cloud-download"
                EnterKey.onClicked: {
                    if (opensearchButon.enabled) {
                        installingBusy.visible = true
                        getOpensearch(opensearchTitle.text, opensearchLink.text)
                    }
                }
            }

            Button {
                id: opensearchButon
                visible: downloadError
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Get opensearch")
                enabled: opensearchLink.text && opensearchTitle.text && !downloadBusy.visible
                onClicked: {
                    installingBusy.visible = true
                    getOpensearch(opensearchTitle.text, opensearchLink.text)
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                height: Theme.itemSizeExtraSmall
                width: (parent ? parent.width : Screen.width) - x*2
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                color: Theme.highlightColor
                visible: searchModel.count > 0 || downloadError
                text: installingBusy.visible
                        ? qsTr("Installing search engine...")
                        : downloadError
                          ? qsTr("Can't find opensearch description. Please contact search provider and request adding opensearch description to html head.")
                          : qsTr("Click on search engine above to add")
            }
        }
    }
}
