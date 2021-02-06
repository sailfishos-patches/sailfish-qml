import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.aida64.infopageloader 1.0

Page {
    property int horizPageMargin: {
        if (Theme.horizontalPageMargin) return Theme.horizontalPageMargin
        else return Theme.paddingLarge
    }

    property int    page_id2
    property string page_title2

    SilicaFlickable {
        anchors.fill: parent

        InfoPageLoader {
            id: infopageloader
        }

        Loader {
            id: loader_DetailPage
            anchors.fill: parent
        }

        Loader {
            source: "PullDownMenu.qml"
        }

        VerticalScrollDecorator {}
    }

    Component.onCompleted: {
        var qmlPage
        if (page_id2 == InfoPageLoader.PAGEENUM_SENSORS) qmlPage = "SensorsPageItem.qml"
        else
        if (page_id2 == InfoPageLoader.PAGEENUM_APPS)    qmlPage = "AppsPageItem.qml"
        else                                             qmlPage = "DetailPageItem.qml"
        loader_DetailPage.setSource(Qt.resolvedUrl(qmlPage), {page_id:page_id2});
    }
}
