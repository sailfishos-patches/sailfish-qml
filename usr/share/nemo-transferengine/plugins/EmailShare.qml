import QtQuick 2.2
import Sailfish.Silica 1.0
import Sailfish.Email 1.1
import Sailfish.Gallery 1.0

EmailComposerPage {
    id: sharePage

    property url source
    property var sources: [source]
    property variant content
    readonly property bool isPlainText: !!content && ('type' in content) && content.type === "text/plain"
    // mimick dialog interface as in ShareDialog
    property alias shareEndDestination: sharePage.popDestination

    allowedOrientations: Orientation.All
    emailBody: content
                 && content.type
                 && ('status' in content) ? content.status : ""

    Component.onCompleted: {
        if ((source == '') && content && ('data' in content) && content.data && !sharePage.isPlainText) {
            var path = tempWriter.writeToFile(content.data, content.name || 'data', '')
            if (!path) {
                console.log('Unable to store content to temporary file location.')
            } else {
                attachmentsModel.append({"url": 'file://' + path, "title": content.name, "mimeType": content.type})
            }
        }
    }

    Instantiator {
        model: sources
        FileInfo {
            source: modelData
            Component.onCompleted: {
                var title = ""
                var url = modelData + ""
                if (content && ('name' in content)) {
                    title = content.name
                } else {
                    var fnIndex = url.lastIndexOf('/')
                    if (fnIndex >= 0) {
                        title = decodeURIComponent(url.slice(fnIndex+1))
                    }
                }
                attachmentsModel.append({
                    "url": url,
                    "title": title || fileName,
                    "mimeType": mimeType,
                    "fileSize": size
                })
            }
        }
    }

    TempFileWriter {
        id: tempWriter
    }
}
