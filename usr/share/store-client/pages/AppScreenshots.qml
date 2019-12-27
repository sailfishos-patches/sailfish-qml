import QtQuick 2.0
import Sailfish.Silica 1.0

Item {
    id: self

    property var urls: []

    width: parent.width
    height: childrenRect.height

    Row {
       id: row

       width: parent.width

       Repeater {
           id: repeater

           // keep track of the images that have finished loading, as the UI
           // design proposes loading sequentially from left to right, showing
           // a spinner on the image that is currently loading
           property int loadingOffset

           model: self.urls

           delegate: Item {
               width: row.width / 3
               height: row.width / 3

               StoreImage {
                   id: img
                   image: (index > repeater.loadingOffset) ? "" : modelData
                   visible: false

                   onImageStatusChanged: {
                       if (image && imageStatus !== Image.Loading) {
                           // advance to the next image, if the image stopped
                           // loading (has loaded or failed)
                           repeater.loadingOffset = Math.max(repeater.loadingOffset, index + 1)
                       }
                   }
               }

               ShaderEffectSource {
                   // Notice that this is consuming quite a bit of memory.
                   // The optimal solution would be to use QImage.scaled()
                   // when we have the disk caching available.
                   property int size: Math.min(img.width, img.height)
                   property real hsize: size / 2.0

                   anchors.fill: parent
                   smooth: true
                   mipmap: true
                   sourceItem: img
                   textureSize { width: size; height: size }
                   sourceRect: Qt.rect(img.width / 2.0 - hsize, img.height / 2.0 - hsize, size, size)
               }

               BusyIndicator {
                   anchors.centerIn: parent
                   running: img.imageStatus === Image.Loading
               }

               MouseArea {
                   anchors.fill: parent

                   onClicked: {
                       if (!jollaStore.isOnline) {
                           jollaStore.tryGoOnline()
                       } else {
                           var props = { "model": self.urls,
                                         "currentIndex": model.index }
                           pageStack.push(Qt.resolvedUrl("ScreenshotPage.qml"), props)
                       }
                   }
               }
           }
       }
    }
}
