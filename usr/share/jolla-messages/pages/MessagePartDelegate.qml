import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.contacts 1.0
import Nemo.Notifications 1.0
import Sailfish.Contacts 1.0
import com.jolla.messages 1.0
import "conversation"

AttachmentDelegate {
    id: delegate

    property Person singlePerson: vcardModel.count === 1 ? vcardModel.getPerson(0) : null
    property string avatarUrl: singlePerson ? singlePerson.filteredAvatarUrl(['local', 'picture', '']) : ""
    property var time
    property bool showFullImage
    property bool isLandscape: status === Image.Ready && implicitWidth > implicitHeight

    source: avatarUrl != "" ? avatarUrl : (isThumbnail ? messagePart.path : "")
    fillMode: showFullImage ? Image.PreserveAspectFit : Image.PreserveAspectCrop
    height: showFullImage && isLandscape ? implicitHeight * width / implicitWidth : width
    highlighted: mouseArea.highlighted

    function extensionForType(mimeType) {
        var typeMap = { "image/jpeg": ".jpg",
                        "image/png": ".png",
                        "image/gif": ".gif" }
        return typeMap[mimeType]
    }

    function padNumber(num) {
        var padded = num.toString()
        while (padded.length < 2) {
            padded = "0" + padded
        }
        return padded
    }

    Notification {
        id: saveNotification
        //% "Saved photo"
        body: qsTrId("messages-la-saved_photo")
        previewBody: body
        previewSummary: summary
        appIcon: "icon-launcher-messaging"
    }

    BackgroundItem {
        id: mouseArea
        anchors.fill: parent
        opacity: Theme.opacityHigh
        onClicked: {
            if (isThumbnail) {
                var page = pageStack.push("ImageView.qml", { 'source': delegate.source, 'messagePart': delegate.messagePart })
                page.copy.connect(function() {
                    var filename = "mms-" + time.getFullYear() + padNumber(time.getMonth()+1) + padNumber(time.getDate())
                    var dest = FileUtils.saveFile(delegate.source, filename, extensionForType(delegate.messagePart.contentType),
                                                  FileUtils.PicturesLocation, "MMS")
                    if (dest.length && dest.lastIndexOf("/") >= 0) {
                        saveNotification.replacesId = 0 // create new
                        var destinationFilename = dest.substring(dest.lastIndexOf("/") + 1)
                        saveNotification.summary = destinationFilename
                        saveNotification.remoteActions = [ {
                                                              "name": "default",
                                                              //: Display text for notification action
                                                              //% "Open file"
                                                              "displayName": qsTrId("jolla-messages-open_file"),
                                                              "service": "com.jolla.gallery",
                                                              "path": "/com/jolla/gallery/ui",
                                                              "iface": "com.jolla.gallery.ui",
                                                              "method": "openFile",
                                                              "arguments": [dest]
                                                          } ]
                        saveNotification.publish()
                    } else {
                        //% "Error saving photo"
                        var previewBody = qsTrId("messages-la-error_saving_photo")
                        mainPage.publishNotification(previewBody)
                    }
                })
            } else if (vcardModel.count > 1) {
                pageStack.animatorPush("VCardView.qml", { 'model': vcardModel })
            } else if (vcardModel.count == 1) {
                pageStack.animatorPush("ImportContactPage.qml", { 'contact': vcardModel.getPerson(0) })
            } else {
                Qt.openUrlExternally(delegate.messagePart.path)
            }
        }
    }

    Label {
        id: nameLabel
        x: Theme.horizontalPageMargin
        y: Theme.paddingLarge
        width: parent.width - 2*Theme.horizontalPageMargin
        horizontalAlignment: Text.AlignRight
        wrapMode: Text.Wrap
        color: highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
        visible: vcardModel.count > 0
        //: The count of contacts in a VCard. This will only be shown for a count of greater than 1.
        //% "%n contacts"
        text: singlePerson ? getNameText(singlePerson) : qsTrId("jolla-messages-la-n-contacts", vcardModel.count)
    }

    function getNameText(contact) {
        if (contact) {
            if (contact.firstName || contact.lastName) {
                if (contact.firstName && contact.lastName) {
                    return contact.firstName + '\n' + contact.lastName
                }
                return contact.firstName ? contact.firstName : contact.lastName
            }
            return contact.displayLabel
        }
        return ''
    }

    PeopleVCardModel {
        id: vcardModel
        source: isVCard ? messagePart.path : ""
    }
}

