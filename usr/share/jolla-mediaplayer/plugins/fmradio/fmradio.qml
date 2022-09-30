// -*- qml -*-

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Media 1.0
import com.jolla.mediaplayer 1.0
import com.jolla.mediaplayer.radio 1.0
import org.nemomobile.configuration 1.0
import QtMultimedia 5.0
import Amber.Mpris 1.0

Page {
    id: root

    property var model // set by framework, should have a better interface
    property string searchText // unused, just expected by mediaplayer page push

    property var bookmarks: model
    property var availableStations: []
    property Component cover: Component {
        CoverBackground {
            Image {
                anchors.fill: parent
                source: "image://theme/graphic-cover-fmradio"
            }

            Column {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Theme.paddingLarge
                width: parent.width

                Label {
                    text: formatter.formatMegahertz(radio.frequency / 1000000)
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.pixelSize: Theme.fontSizeHuge
                }

                Item {
                    width: 1
                    height: Theme.paddingSmall
                }

                Label {
                    width: Math.min(parent.width - Theme.paddingMedium, implicitWidth)
                    x: Math.max((parent.width - width) / 2, Theme.paddingMedium)
                    truncationMode: TruncationMode.Fade
                    font.pixelSize: Theme.fontSizeSmall
                    text: stationText.text
                }

                Label {
                    width: Math.min(parent.width - Theme.paddingMedium, implicitWidth)
                    x: Math.max((parent.width - width) / 2, Theme.paddingMedium)
                    truncationMode: TruncationMode.Fade
                    color: Theme.secondaryColor
                    font.pixelSize: Theme.fontSizeExtraSmall
                    text: radioText.text
                }
            }
        }
    }
    property ProxyMprisPlayer mprisPlayer: ProxyMprisPlayer {
        // Mpris2 Player Interface
        canControl: true
        canGoNext: radio.antennaConnected
        canGoPrevious: radio.antennaConnected
        canPause: radio.antennaConnected
        canPlay: radio.antennaConnected
        canSeek: false
        loopStatus: Mpris.LoopNone

        metaData.contributingArtist: formatter.formatMegahertz(radio.frequency / 1000000) + " MHz"
        metaData.title: radio.radioData.stationName.trim()

        playbackStatus: radio.active ? Mpris.Playing : Mpris.Stopped
        shuffle: false
        volume: 1

        onPauseRequested: radio.stop()
        onPlayRequested: radio.start()
        onPlayPauseRequested: radio.togglePlayPause()
        onStopRequested: radio.stop()
        onNextRequested: radio.scanUp()
        onPreviousRequested: radio.scanDown()
    }

    onStatusChanged: {
        // we don't want two panels
        if (status == PageStatus.Activating || status == PageStatus.Active) {
            dockedPanel().hide(true)
        }
    }

    ConfigurationValue {
        id: lastFrequency

        key: "/apps/jolla-mediaplayer/radio_last_frequency"
        defaultValue: 0
    }

    Radio {
        id: radio

        // TODO: overriding Radio property. Can be removed when plugin detects antenna state.
        // This will ask antenna during phone call, but assume no one is around to see it.
        property bool antennaConnected: audioRoute.allowed
        property var _stationsFound: []
        property bool _searchingAll
        property bool active: state === Radio.ActiveState

        band: Radio.FM
        onFrequencyChanged: channelList.update()
        onStationFound: {
            _stationsFound.push(frequency)
        }

        onSearchingChanged: {
            if (!_searchingAll) {
                return
            }

            if (searching) {
                _stationsFound = []
                availableStations = _stationsFound
            } else {
                // Iris backend returns everything when search is finished. not bother to do incremental additions
                _stationsFound.sort(function(first, second) { return first - second } )
                availableStations = _stationsFound
                _searchingAll = false
            }
        }

        onStateChanged: {
            if (state === Radio.ActiveState) {
                startPlay()
            }
        }

        Component.onCompleted: {
            if (lastFrequency.value > 0) {
                radio.frequency = lastFrequency.value
            }
        }

        function searchAll() {
            _searchingAll = true
            searchAllStations(Radio.SearchFast)
        }

        function cancelSearchAll() {
            _searchingAll = false
            cancelScan()
        }

        function startPlay() {
            if (audioRoute.allowed) {
                if (radio.state === Radio.StoppedState) {
                    radio.start()
                }

                if (!audioResource.acquired) {
                    audioResource.acquire()
                }

                if (audioResource.acquired && radio.state === Radio.ActiveState) {
                    audioRoute.enable()
                }
            }
        }

        function stopPlay() {
            radio.stop()
            audioRoute.disable()
            if (audioResource.acquired)
                audioResource.release()
        }

        function togglePlayPause() {
            if (radio.active) {
                radio.stopPlay()
            } else {
                radio.startPlay()
            }
        }
    }

    FrequencyFormatter {
        id: formatter
    }

    AudioResource {
        id: audioResource

        onAcquiredChanged: {
            if (acquired && audioRoute.allowed) {
                radio.startPlay()
            } else {
                radio.stopPlay()
            }
        }
    }

    AudioRoute {
        id: audioRoute

        onAllowedChanged: {
            if (allowed) {
                radio.startPlay()
            } else {
                radio.stopPlay()
            }
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: parent.height

        SilicaListView {
            id: channelList

            model: radio.antennaConnected ? bookmarks : 0
            width: parent.width
            height: parent.height - panelContent.height
            clip: true
            header: PageHeader {
                //% "FM Radio"
                title: qsTrId("mediaplayer-radio-he-fm_radio")
            }

            currentIndex: -1
            onModelChanged: update()

            function update() {
                if (radio.antennaConnected) {
                    currentIndex = bookmarks.findByFrequency(radio.frequency)
                    lastFrequency.value = radio.frequency
                }
            }

            delegate: ListItem {
                id: listItem

                menu: contextMenu

                onClicked: {
                    radio.frequency = model.frequency
                    radio.startPlay()
                }

                function edit() {
                    var obj = pageStack.animatorPush(renamePage, { name: model.name })
                    obj.pageCompleted.connect(function(dialog) {
                        dialog.accepted.connect(function() {
                            bookmarks.modifyName(model.index, dialog.name)
                        })
                    })
                }

                function remove() {
                    bookmarks.remove(model.index)
                    channelList.update()
                }

                Label {
                    id: frequencyText

                    width: Theme.itemSizeExtraLarge
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Text.AlignRight
                    font.pixelSize: Theme.fontSizeLarge
                    color: (listItem.highlighted || listItem.ListView.isCurrentItem) ? Theme.highlightColor
                                                                                     : Theme.secondaryColor
                    text: formatter.formatMegahertz(model.frequency / 1000000)
                }
                Label {
                    anchors.left: frequencyText.right
                    anchors.right: parent.right
                    anchors.leftMargin: Theme.paddingMedium
                    anchors.baseline: frequencyText.baseline
                    font.pixelSize: Theme.fontSizeMedium
                    elide: Text.ElideRight
                    color: (listItem.highlighted || listItem.ListView.isCurrentItem) ? Theme.highlightColor
                                                                                     : Theme.primaryColor
                    text: model.name
                }

                Component {
                    id: contextMenu

                    ContextMenu {
                        MenuItem {
                            //% "Rename"
                            text: qsTrId("jolla-mediaplayer-radio-rename")
                            onClicked: listItem.edit()
                        }
                        MenuItem {
                            //% "Delete"
                            text: qsTrId("jolla-mediaplayer-radio-delete")
                            onClicked: listItem.remove()
                        }
                    }
                }
            }

            InfoLabel {
                visible: !radio.antennaConnected
                anchors.verticalCenter: parent.verticalCenter
                //: Placeholder text on radio main page
                //% "Plug in your earphones. They are used as radio antenna"
                text: qsTrId("jolla-mediaplayer-radio-attach_earphones_hint")
            }
        }

        MediaPlayerPanelBackground {
            width: parent.width
            height: panelContent.height
            anchors.top: channelList.bottom

            BusyIndicator {
                size: BusyIndicatorSize.Small
                anchors.horizontalCenter: parent.horizontalCenter
                y: stationText.y
                running: radio.searching
            }

            Column {
                id: panelContent

                width: parent.width
                opacity: enabled ? 1.0 : 0.6
                enabled: radio.antennaConnected

                Item {
                    width: 1
                    height: root.isLandscape ? Theme.paddingSmall : Theme.paddingMedium
                }

                Item {
                    width: parent.width
                    height: tuner.height

                    IconButton {
                        property bool bookmarked: channelList.currentIndex >= 0

                        visible: !tuner.adjusting
                        width: parent.width / 3
                        anchors.verticalCenter: parent.verticalCenter
                        icon.source: bookmarked ? "image://theme/icon-m-favorite-selected" : "image://theme/icon-m-favorite"
                        onClicked: {
                            if (bookmarked) {
                                bookmarks.remove(channelList.currentIndex)
                            } else {
                                bookmarks.addStation(radio.radioData.stationName.trim(),
                                                     radio.radioData.stationId.trim(),
                                                     radio.frequency)
                            }
                            channelList.update()
                        }
                    }

                    IconButton {
                        visible: tuner.adjusting
                        width: parent.width / 3
                        anchors.verticalCenter: parent.verticalCenter
                        icon.source: "image://theme/icon-m-left"
                        onClicked: {
                            radio.tuneDown()
                            adjustAutoStop.restart()
                        }
                    }

                    Text {
                        id: tuner

                        property bool adjusting

                        text: formatter.formatMegahertz(radio.frequency / 1000000)
                        font.pixelSize: Theme.fontSizeHuge
                        color: tunerMouseArea.pressed ? Theme.highlightColor : Theme.primaryColor
                        anchors.horizontalCenter: parent.horizontalCenter

                        Timer {
                            id: adjustAutoStop
                            interval: 5000
                            onTriggered: tuner.adjusting = false
                        }

                        MouseArea {
                            id: tunerMouseArea
                            anchors.fill: parent
                            onClicked: {
                                tuner.adjusting = !tuner.adjusting
                                if (tuner.adjusting) {
                                    adjustAutoStop.restart()
                                }
                            }
                        }
                    }

                    Text {
                        visible: !tuner.adjusting
                        anchors.left: tuner.right
                        anchors.leftMargin: Theme.paddingSmall
                        anchors.baseline: tuner.baseline
                        color: Theme.primaryColor
                        text: "MHz"
                    }

                    IconButton {
                        visible: !tuner.adjusting
                        width: parent.width / 3
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        icon.source: audioRoute.routeToSpeaker ? "image://theme/icon-m-speaker-on"
                                                               : "image://theme/icon-m-speaker"
                        onClicked: audioRoute.routeToSpeaker = !audioRoute.routeToSpeaker
                    }

                    IconButton {
                        visible: tuner.adjusting
                        width: parent.width / 3
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        icon.source: "image://theme/icon-m-right"
                        onClicked: {
                            radio.tuneUp()
                            adjustAutoStop.restart()
                        }
                    }
                }
                Label {
                    id: stationText

                    property string trimmedText: radio.radioData.stationName.trim()
                    text: trimmedText != "" ? trimmedText : " "
                    width: Math.min(parent.width - Theme.paddingMedium, implicitWidth)
                    x: Math.max((parent.width - width) / 2, Theme.paddingMedium)
                    truncationMode: TruncationMode.Fade
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.primaryColor
                }
                Label {
                    id: radioText

                    property string trimmedText: radio.radioData.radioText.trim()
                    text: trimmedText != "" ? trimmedText : " "
                    width: Math.min(parent.width - Theme.paddingMedium, implicitWidth)
                    x: Math.max((parent.width - width) / 2, Theme.paddingMedium)
                    truncationMode: TruncationMode.Fade
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: Theme.secondaryColor
                }

                Item {
                    width: 1
                    height: Theme.paddingLarge
                }

                Row {
                    id: navigation
                    width: parent.width

                    IconButton {
                        id: gotoPrevious
                        width: parent.width / 3
                        icon.source: "image://theme/icon-m-previous"
                        anchors.verticalCenter: parent.verticalCenter
                        onPressAndHold: radio.scanDown()
                        onClicked: {
                            radio.scanDown()
                        }
                    }

                    IconButton {
                        id: playPause

                        width: parent.width / 3
                        icon.source: radio.active ? "image://theme/icon-m-pause"
                                                  : "image://theme/icon-m-play"
                        onClicked: radio.togglePlayPause()
                    }

                    IconButton {
                        id: gotoNext
                        width: parent.width / 3
                        icon.source: "image://theme/icon-m-next"
                        anchors.verticalCenter: parent.verticalCenter
                        onPressAndHold: radio.scanUp()
                        onClicked: {
                            radio.scanUp()
                        }
                    }
                }
                Item {
                    width: 1
                    height: (root.isLandscape ? 1 : 2) * Theme.paddingLarge
                }
            }
        }

        PushUpMenu {
            visible: radio.antennaConnected

            BackgroundItem {
                id: channelButton

                anchors.horizontalCenter: parent.horizontalCenter
                height: icon.height + iconText.height + 2*Theme.paddingSmall
                width: Math.max(Theme.itemSizeHuge, iconText.width + 2*Theme.paddingSmall)
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("ChannelSearchPage.qml"),
                                                  {   radio: radio,
                                                      availableStations: Qt.binding(function() { return availableStations } ),
                                                      bookmarks: bookmarks
                                                  })

                Image {
                    id: icon

                    y: Theme.paddingSmall
                    anchors.horizontalCenter: parent.horizontalCenter
                    source: "image://theme/icon-m-media-radio" + (channelButton.highlighted ? ("?" + Theme.highlightColor)
                                                                                            : "")
                }
                Text {
                    id: iconText

                    anchors.top: icon.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: channelButton.highlighted ? Theme.highlightColor : Theme.primaryColor
                    //% "Available channels"
                    text: qsTrId("jolla-mediaplayer-radio-available_channels")
                }
            }
        }
    }

    Component {
        id: renamePage

        Dialog {
            id: dialog
            property alias name: nameEditor.text

            Column {
                width: parent.width

                DialogHeader {
                }
                TextField {
                    id: nameEditor

                    width: parent.width
                    focus: true
                    //: Channel name editor placeholder text
                    //% "Channel name"
                    placeholderText: qsTrId("jolla-mediaplayer-radio-channel_name")
                    label: placeholderText
                    EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                    EnterKey.onClicked: dialog.accept()
                }
            }
        }
    }
}
