import QtQuick 2.2
import Sailfish.Silica 1.0
import "../callhistory"
import "../../common/CallHistory.js" as CallHistory

Page {
    id: conferenceManager

    SilicaListView {
        width: parent.width
        anchors {
            top: parent.top
            bottom: endCallButton.top
        }

        clip: contentHeight > height

        onCountChanged: {
            if (conferenceManager.status === PageStatus.Active && count < 2) {
                callDialogApplicationWindow.pageStack.pop()
            }
        }

        header: PageHeader {
            //% "Conference call"
            title: qsTrId("voicecall-he-conference_call")
        }

        model: telephony.conferenceCall ? telephony.conferenceCall.childCalls : null
        delegate: CallHistoryItem {
            remoteUid: lineId
            time: startedAt
            person: telephony.callerDetails[handlerId].person

            onClicked: openMenu()
/*
            dateColumnVisible: false
            Label {
                id: durationLabel
                anchors {
                    right: parent.right
                    rightMargin: Theme.horizontalPageMargin
                    baseline: parent.baseline
                }
                text: CallHistory.durationText(instance.duration)
            }
            */
            menu: ContextMenu {
                MenuItem {
                    //% "End call"
                    text: qsTrId("voicecall-me-end_call")
                    onClicked: instance.hangup()
                }
                MenuItem {
                    //% "Split call"
                    text: qsTrId("voicecall-me-split_call")
                    visible: telephony.effectiveCallCount === 1
                    onClicked: {
                        telephony.split(instance)
                        callDialogApplicationWindow.pageStack.pop()
                    }
                }
            }
        }
    }

    Button {
        id: endCallButton
        text: qsTrId("voicecall-bt-end_call")
        preferredWidth: Theme.buttonWidthMedium
        height: Theme.itemSizeLarge
        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }
        onClicked: telephony.hangupCall(telephony.conferenceCall)
    }
}
