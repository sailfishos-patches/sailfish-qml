import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: root

    property int startYear: 1980
    property int endYear: 2300
    property int defaultYear: 2100

    signal yearSelected(int year)

    SilicaListView {
        id: view
        anchors.fill: parent
        model: root.endYear - root.startYear
        delegate: BackgroundItem {
            width: parent.width
            height: dateText.height
            Label {
                id: dateText
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: index + root.startYear
                color: index == view.currentIndex || highlighted ? Theme.highlightColor : Theme.primaryColor
                font.pixelSize: Theme.fontSizeHuge
            }
            onClicked: {
                view.currentIndex = index
                root.yearSelected(index + root.startYear)
                pageStack.pop()
            }
        }
    }

    Component.onCompleted: {
        var index = defaultYear - startYear
        view.positionViewAtIndex(index, ListView.Center)
        view.currentIndex = index
    }
}
