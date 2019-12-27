import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: typeMenuPage
    property ContextMenu menu
    property QtObject typesModel
    property int currentIndex: -1

    SilicaListView {
        anchors.fill: parent
        header: PageHeader {
            //% "Message type"
            title: qsTrId("jolla-messages-la-message_type")
        }
        model: typesModel
        delegate: BackgroundItem {
            highlighted: down || typeMenuPage.currentIndex === model.index
            onClicked: {
                menu.activated(model.index)
                menu.closed()
                pageStack.pop()
            }
            TypeMenuItem {
                color: highlighted ? Theme.highlightColor : Theme.primaryColor
            }
        }
        VerticalScrollDecorator {}
    }
}
