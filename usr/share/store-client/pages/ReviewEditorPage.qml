import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page
    objectName: "ReviewEditorPage"

    property alias uuid: reviewEditor.uuid
    property alias appUuid: reviewEditor.appUuid
    property alias packageVersion: reviewEditor.packageVersion
    property alias text: reviewEditor.text

    onStatusChanged: {
        if (status === PageStatus.Active) {
           reviewEditor.forceActiveFocus()
        }
    }

    PageHeader {
        id: pageHeader
        //: Page header for the comments page
        //% "Update comment"
        title: qsTrId("jolla-store-he-udpate_comment")
    }

    ReviewEditor {
        id: reviewEditor
        anchors.top: pageHeader.bottom
        width: parent.width

        onReviewReady: {
            pageStack.pop()
        }
    }
}
