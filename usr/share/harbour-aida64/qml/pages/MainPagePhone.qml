import QtQuick 2.0
import Sailfish.Silica 1.0

SilicaListView {
    id: listView_PageList
    model: pageListModel
    anchors.fill: parent
    header: PageHeader {
        title: APP_NAME
    }
    delegate: BackgroundItem {
        id: delegate

        Label {
            x: horizPageMargin
            text: infopageloader.getPageTitle(pid) + lcs.emptyString
            anchors.verticalCenter: parent.verticalCenter
            color: delegate.highlighted ? Theme.highlightColor : Theme.primaryColor
        }

        onClicked: pageStack.push(Qt.resolvedUrl("DetailPage.qml"), {page_id2: pid})
    }

    Loader {
        source: "PullDownMenu.qml"
    }

    VerticalScrollDecorator {}
}
