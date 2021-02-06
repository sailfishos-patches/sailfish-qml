import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.aida64.infopageloader 1.0

Page {
    id: mainPage

    property int horizPageMargin: {
        if (Theme.horizontalPageMargin) return Theme.horizontalPageMargin
        else return Theme.paddingLarge
    }

    InfoPageLoader {
        id: infopageloader
    }

    ListModel {
           id: pageListModel
           ListElement { pid: InfoPageLoader.PAGEENUM_SYSTEM }
           ListElement { pid: InfoPageLoader.PAGEENUM_CPU }
           ListElement { pid: InfoPageLoader.PAGEENUM_DISPLAY }
           ListElement { pid: InfoPageLoader.PAGEENUM_NETWORK }
           ListElement { pid: InfoPageLoader.PAGEENUM_BATTERY }
           ListElement { pid: InfoPageLoader.PAGEENUM_SAILFISH }
           ListElement { pid: InfoPageLoader.PAGEENUM_DEVICES }
           ListElement { pid: InfoPageLoader.PAGEENUM_THERMAL }
           ListElement { pid: InfoPageLoader.PAGEENUM_SENSORS }
           ListElement { pid: InfoPageLoader.PAGEENUM_APPS }
           ListElement { pid: InfoPageLoader.PAGEENUM_DIRS }
           ListElement { pid: InfoPageLoader.PAGEENUM_SYSFILES }
           ListElement { pid: InfoPageLoader.PAGEENUM_ABOUT }
    }

    Loader {
        source: Screen.sizeCategory >= Screen.Large
                ? "MainPageTablet.qml"
                : "MainPagePhone.qml"

        anchors.fill: parent
    }
}
