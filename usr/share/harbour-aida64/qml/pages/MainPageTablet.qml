import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.aida64.infopageloader 1.0

SilicaFlickable {
    anchors.fill: parent

    property int selectedPage

    Row {
        id: row_Main
        anchors.fill: parent

        SilicaListView {
            id: listView_PageList
            width: parent.width * 0.28
            height: parent.height
            model: pageListModel
            header: PageHeader { }
            delegate: BackgroundItem {
                id: delegate

                Label {
                    id: pageLabel
                    x: horizPageMargin
                    width: parent.width
                    text: infopageloader.getPageTitle(pid) + lcs.emptyString
                    anchors.verticalCenter: parent.verticalCenter
                    wrapMode: Label.WordWrap
                    color: selectedPage == pid ? Theme.highlightColor : Theme.primaryColor
                }

                onClicked: {
                    selectedPage = pid

                    var qmlPage;
                    if (pid === InfoPageLoader.PAGEENUM_SENSORS) qmlPage = "SensorsPageItem.qml"
                    else
                    if (pid === InfoPageLoader.PAGEENUM_APPS)    qmlPage = "AppsPageItem.qml"
                    else                                         qmlPage = "DetailPageItem.qml"
                    loader_DetailPage.setSource(Qt.resolvedUrl(qmlPage), {page_id: pid, tabletLayout:1});
                }
            }

            VerticalScrollDecorator {}
        }

        Loader {
            id: loader_DetailPage
            width: parent.width - listView_PageList.width
            height: parent.height
        }
    }

    Loader {
        source: "PullDownMenu.qml"
    }

    Component.onCompleted: {
        selectedPage = InfoPageLoader.PAGEENUM_SYSTEM
        loader_DetailPage.setSource(Qt.resolvedUrl("DetailPageItem.qml"), {page_id: selectedPage, tabletLayout:1});
    }
}
