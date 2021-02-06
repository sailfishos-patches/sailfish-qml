import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.aida64.infopageloader 1.0

Page {
    property int horizPageMargin: {
        if (Theme.horizontalPageMargin) return Theme.horizontalPageMargin
        else return Theme.paddingLarge
    }

    property bool uploadDone: false

    InfoPageLoader {
        id: infopageloader
    }

    SilicaFlickable {
        anchors {
            left: parent.left
            top: parent.top
            topMargin: horizPageMargin
            right: parent.right
            bottom: btnStartUpload.top
            bottomMargin: horizPageMargin
        }

        clip: true
        contentHeight: rptUploadContent.height

        Label {
            id: rptUploadContent
            x: horizPageMargin
            width: parent.width - 2 * x
            color: Theme.primaryColor
            font.pixelSize: Theme.fontSizeExtraSmall
            wrapMode: Text.Wrap
        }

        VerticalScrollDecorator {}
    }

    Button {
        id: btnStartUpload
        anchors.bottom: parent.bottom
        width: parent.width
        text: qsTrId("button_start_upload") + lcs.emptyString

        onClicked: {
            if (uploadDone) pageStack.navigateBack(PageStackAction.Animated);
            else {
                btnStartUpload.enabled = false
                btnStartUpload.text = qsTrId("network_page_datastate_connecting") + "..." + lcs.emptyString
                uploadDone = false

                var boundary = "--------022420102133518"
                var twoDashes = "--"
                var crlf = "\r\n"

                var http = new XMLHttpRequest()
                http.open("POST", infopageloader.ffru(), true)
                http.timeout = 20000
                http.setRequestHeader("Authorization", "Basic " +
                                      Qt.btoa(infopageloader.ffruu() + ":" + infopageloader.ffrup()))
                http.setRequestHeader("Content-Type", "multipart/form-data; boundary=" + boundary)

                http.onreadystatechange = function() {
                    if (http.readyState == 4) {
                        if (http.status == 200) rptUploadContent.text = http.responseText
                        else                    rptUploadContent.text = "HTTP Error: " + http.status

                        rptUploadContent.color = Theme.highlightColor
                        rptUploadContent.font.pixelSize = Theme.fontSizeSmall
                        btnStartUpload.text = qsTrId("button_done") + lcs.emptyString
                        btnStartUpload.enabled = true
                        uploadDone = true
                    }
                }

                var req = twoDashes + boundary + crlf +
                        "Content-Disposition: form-data; name=\"uploadEmailFrom\"" + crlf +
                        crlf +
                        "Anonymous <anonymous@anonymous.com>" + crlf +

                        twoDashes + boundary + crlf +
                        "Content-Disposition: form-data; name=\"uploadEmailSubj\"" + crlf +
                        crlf +
                        APP_NAME + " for Sailfish v" + APP_VERSION + " Report" + crlf +

                        twoDashes + boundary + crlf +
                        "Content-Disposition: form-data; name=\"uploadEmailBody\"" + crlf +
                        crlf +
                        rptUploadContent.text + crlf +

                        twoDashes + boundary + crlf +
                        "Content-Disposition: form-data; name=\"uploadEncoding\"" + crlf +
                        crlf +
                        "utf-8" + crlf +

                        twoDashes + boundary + crlf +
                        "Content-Disposition: form-data; name=\"uploadWord\"" + crlf +
                        crlf +
                        infopageloader.ffrum() + crlf +

                        twoDashes + boundary + twoDashes + crlf

                http.send(req)
            }
        }
    }

    Component.onCompleted: {
        rptUploadContent.text = infopageloader.generateReport(true)
    }
}
