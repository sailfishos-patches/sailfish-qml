import QtQuick 2.0
import Amber.Mpris 1.0

QtObject {
    // Proxy for the Mpris2 Player
    property bool canControl
    property bool canGoNext
    property bool canGoPrevious
    property bool canPause
    property bool canPlay
    property bool canSeek
    property int loopStatus: Mpris.LoopNone
    property real maximumRate: 1
    property real minimumRate: 1
    property int playbackStatus: Mpris.Stopped
    property int position
    property real rate: 1
    property bool shuffle
    property real volume

    property ProxyMprisMetaData metaData: ProxyMprisMetaData {}

    signal positionRequested()
    signal pauseRequested()
    signal playRequested()
    signal playPauseRequested()
    signal stopRequested()
    signal nextRequested()
    signal previousRequested()
    signal seekRequested(int offset)
    signal setPositionRequested(string trackId, int position)
    signal openUriRequested(url uri)
    signal loopStatusRequested(int loopStatus)
    signal shuffleRequested(bool shuffle)
}
