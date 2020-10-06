import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Contacts 1.0
import org.nemomobile.voicecall 1.0
import org.nemomobile.contacts 1.0
import org.nemomobile.dbus 2.0

Page {
    id: root

    property alias model: listView.model

    SilicaListView {
        id: listView

        function next() {
            currentIndex = currentIndex == listView.count - 1 ? 0 : currentIndex + 1
            selectCurrentItem()
        }

        function previous() {
            currentIndex = currentIndex == 0 ? listView.count - 1 : currentIndex - 1
            selectCurrentItem()
        }

        function selectCurrentItem() {
            var item = currentItem
            if (item.remorse && item.remorse.pending) {
                closeControls()
                deselectCurrentItem()
                return
            }

            playerControls.firstNameText = item.firstNameText
            playerControls.lastNameText = item.lastNameText
            playerControls.filePath = item.filePath
            playerControls.open = true
        }

        function deselectCurrentItem() {
            currentIndex = -1
        }

        function closeControls() {
            playerControls.firstNameText = ''
            playerControls.lastNameText = ''
            playerControls.filePath = ''
            playerControls.open = false
        }

        anchors.fill: parent
        anchors.bottomMargin: playerControls.visibleSize
        clip: true

        header: PageHeader {
            //% "Recorded calls"
            title: qsTrId("settings_voicecall-he-recorded_calls")
        }

        currentIndex: -1

        onModelChanged: currentIndex = -1

        delegate: ListItem {
            id: delegate

            property string filePath: model.absolutePath
            property alias firstNameText: firstNameText.text
            property alias lastNameText: lastNameText.text
            property int listIndex: index
            property bool selected: ListView.isCurrentItem
            property Item remorse

            property bool privateNumber: remoteUid == 'unknown'

            // Duration (ms) derived from file size, assuming 8kHz 16-bit mono recordings
            property int duration: Math.max(model.size - 44, 0) / (8000 * 2)

            property string numberDetail: {
                var label = ""
                if (contact.id) {
                    var numbers = Person.removeDuplicatePhoneNumbers(contact.phoneDetails)
                    for (var i = 0; i < numbers.length && numbers.length > 1; i++) {
                        if (numbers[i].normalizedNumber == remoteUid) {
                            var detail = numbers[i]
                            label = ContactsUtil.getNameForDetailType(detail.type, detail.label, true)
                            break
                        }
                    }
                }
                return label
            }

            // We need to extract information from the filename
            property string contactLabel
            property string remoteUid
            property bool incoming
            property var fileName: model.fileName
            onFileNameChanged: {
                var decoded = VoiceCallAudioRecorder.decodeRecordingFileName(fileName)
                var match = /(.*)\.([^\.]*)\.[0-9]{8}-[0-9]{9}\.([01])\.wav$/.exec(decoded)
                contactLabel = match[1]
                remoteUid = match[2]
                incoming = match[3] == 1

                contact.resolvePhoneNumber(remoteUid)
            }

            function remove() {
                if (selected) {
                    // Stop the playback and/or close the controls
                    listView.closeControls()
                }
                remorse = remorseDelete(function() {
                    VoiceCallAudioRecorder.deleteRecording(fileName)
                })
            }
            ListView.onRemove: animateRemoval()

            contentHeight: Theme.paddingSmall
                           + detailsAndDuration.y + detailsAndDuration.height
                           + (Theme.paddingSmall * 2)

            onClicked: {
                listView.currentIndex = delegate.listIndex
                listView.selectCurrentItem()
            }

            menu: Component {
                ContextMenu {
                    MenuItem {
                        //% "Call"
                        text: qsTrId("settings_voicecall-me-call")

                        enabled: !privateNumber
                        onClicked: voicecall.call('dial', remoteUid)

                        DBusInterface {
                            id: voicecall

                            service: "com.jolla.voicecall.ui"
                            path: "/"
                            iface: "com.jolla.voicecall.ui"
                        }
                    }
                    MenuItem {
                        //% "Open contact card"
                        text: qsTrId("settings_voicecall-me-open_contact_card")

                        enabled: contact.id
                        onClicked: pageStack.animatorPush('Sailfish.Contacts.ContactCardPage',
                                                  { 'contact': contact, 'activeDetail': remoteUid })
                    }
                    MenuItem {
                        //% "Delete"
                        text: qsTrId("settings_voicecall-me-delete_recording")

                        onClicked: remove()
                    }
                    MenuItem {
                        //% "Share"
                        text: qsTrId("settings_voicecall-me-share")

                        onClicked: pageStack.animatorPush('Sailfish.TransferEngine.SharePage',
                                                          { 'source': model.absolutePath })
                    }
                }
            }

            Person {
                id: contact
            }

            Item {
                id: description

                y: Theme.paddingMedium
                width: parent.width - Theme.horizontalPageMargin
                height: firstNameText.height
                baselineOffset: firstNameText.baselineOffset

                Image {
                    id: icon
                    visible: incoming
                    x: Theme.paddingMedium
                    anchors.verticalCenter: nameRow.verticalCenter
                    source: "image://theme/icon-s-incoming-call" + (highlighted || delegate.selected ? '?' + Theme.highlightColor : '')
                }

                Row {
                    id: nameRow

                    anchors.left: icon.right
                    anchors.leftMargin: Theme.paddingMedium
                    spacing: Theme.paddingSmall
                    width: parent.width - x - timeStampLabel.width - Theme.paddingMedium

                    Label {
                        id: firstNameText
                        opacity: privateNumber ? Theme.opacityHigh : 1.0
                        // tr defined elsewhere
                        text: privateNumber ? qsTrId("voicecall-la-private_number")
                                            : (!contact.id || (contact.primaryName.length === 0 && contact.secondaryName.length === 0)
                                                 ? contactLabel
                                                 : contact.primaryName)
                        color: highlighted || delegate.selected ? Theme.highlightColor : Theme.primaryColor
                        truncationMode: TruncationMode.Fade
                        width: Math.min(implicitWidth, parent.width)
                    }
                    Label {
                        id: lastNameText
                        text: contact.id ? contact.secondaryName : ""
                        color: highlighted || delegate.selected ? Theme.secondaryHighlightColor : Theme.secondaryColor
                        truncationMode: TruncationMode.Fade
                        width: Math.min(implicitWidth, parent.width - firstNameText.width)
                        visible: width > 0
                    }
                }

                Label {
                    id: timeStampLabel
                    text: Format.formatDate(model.modified, Formatter.TimepointRelativeCurrentDay)
                    font.pixelSize: Theme.fontSizeExtraSmall
                    anchors.right: parent.right
                    anchors.baseline: parent.baseline
                    color: highlighted || delegate.selected ? Theme.highlightColor : Theme.primaryColor
                }
            }

            Row {
                id: detailsAndDuration

                spacing: Theme.paddingSmall
                anchors {
                    top: description.bottom
                    right: description.right
                }

                Label {
                    color: highlighted || delegate.selected ? Theme.secondaryHighlightColor : Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeExtraSmall
                    anchors.verticalCenter: parent.verticalCenter
                    text: numberDetail
                }
                Image {
                    source: "image://theme/icon-s-duration" + (highlighted || delegate.selected ? '?' + Theme.highlightColor : '')
                    anchors.verticalCenter: parent.verticalCenter
                }
                Label {
                    color: highlighted || delegate.selected ? Theme.secondaryHighlightColor : Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeExtraSmall
                    anchors.verticalCenter: parent.verticalCenter
                    text: Format.formatDuration(duration, duration >= 3600 ? Formatter.DurationLong : Formatter.DurationShort)
                }
            }
        }

        ViewPlaceholder {
            // Empty state when no recorded calls are present
            //% "No recorded calls"
            text: qsTrId("settings_voicecall-ph-no_recorded_calls")
            enabled: model.populated && listView.count == 0
        }

        VerticalScrollDecorator {}
    }

    PlayerControlsDockedPanel {
        id: playerControls

        z: 1
        dock: Dock.Bottom
        onNextClicked: listView.next()
        onPreviousClicked: listView.previous()
        onOpenChanged: if (!open) listView.deselectCurrentItem()
    }

    Component.onCompleted: {
        if (!ContactsUtil.isInitialized)
            ContactsUtil.init(Person)
    }
}
