import QtQuick 2.0

/* Image element for images from the store server.
 *
 * This element takes care of loading images from the store server
 * asynchronously and without being blocked by load timeouts.
 */
Image {
    // the image requested from the store
    property string image
    readonly property int imageStatus: _storeStatus === Image.Ready
                                       ? status
                                       : _storeStatus

    property bool _completed
    property int _storeStatus: Image.Null

    function _imageLoaded(ok, imageUri) {
        if (ok) {
            source = imageUri
            _storeStatus = Image.Ready
        } else {
            _storeStatus = Image.Error
        }
    }

    function loadImage() {
        if (_completed) {
            if (_storeStatus === Image.Loading) {
                jollaStore.cancelStoreImageCallback(_imageLoaded)
            }
            if (image === "") {
                _storeStatus = Image.Null
                source = ""
            } else {
                _storeStatus = Image.Loading
                jollaStore.loadStoreImage(image, width, height, _imageLoaded)
            }
        }
    }

    Component.onCompleted: {
        _completed = true
        loadImage()
    }

    Component.onDestruction: {
        if (_storeStatus === Image.Loading) {
            jollaStore.cancelStoreImageCallback(_imageLoaded)
        }
    }

    onImageChanged: {
        // invalidate image source first, so that the previous image won't be
        // shown while loading the new one (which may take some time on 2G)
        source = ""
        loadImage()
    }

    onWidthChanged: loadImage()
    onHeightChanged: loadImage()

    asynchronous: true

    onStatusChanged: {
        if (status === Image.Error && source !== "") {
            // reset source so that the image will reload should it become
            // available eventually
            source = ""
        }
    }
}
