/*
 * Copyright (c) 2012 - 2020 Jolla Ltd.
 * Copyright (c) 2019 - 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Telephony 1.0
import com.jolla.voicecall 1.0
import org.nemomobile.messages.internal 1.0 as Messages
import "../common/CallHistory.js" as CallHistory
import "../common"

IncomingCallGesture {
    id: incomingCallView

    // Just the visual interface, don't put any engine or model specific code here!!

    property bool active
    property string phoneNumber
    property string firstText
    property string secondText
    property string numberDetail
    property bool callWaiting
    property bool forwarded
    property bool silenced
    property bool readyForStateChange: !menuLoader.menuOpen && !incomingCallView.animationRunning
    property int callCount
    property alias contentItem: content
    readonly property bool showCountry: phoneNumberParser.localizedCountryName.length > 0
                                        && (telephony.registrationStatus === "roaming" || phoneNumberParser.regionCode !== telephony.country)

    signal answered
    signal endActiveAndAnswered
    signal rejected
    signal rejectedWithSms
    signal muted

    enabled: active || !readyForStateChange
    swipeEnabled: active && readyForStateChange
    opacity: (incomingCallView.active || incomingCallControlFadeoutTimer.running) ? 1.0 : 0.0
    Behavior on opacity { FadeAnimator { duration: 200 } }

    onActiveChanged: {
        if (active) {
            incomingCallView.resetGestures()
        } else {
            incomingCallView.resetGesturesWithDelay()
            menuLoader.closeMenu()
        }
    }

    onAnswerGestureTriggered: {
        if (callWaiting) {
            menuLoader.open("", multiCallMenuComponent)
        } else {
            incomingCallView.answered()
        }
    }

    onHangupGestureTriggered: {
        incomingCallControlFadeoutTimer.start()
        incomingCallView.muted()
    }

    PhoneNumber {
        id: phoneNumberParser
        defaultRegionCode: telephony.country
        rawPhoneNumber: phoneNumber
    }

    Timer {
        id: incomingCallControlFadeoutTimer
        interval: 500
    }

    CallerItem {
        id: callerItem
        person: telephony.primaryCallerDetails ? telephony.primaryCallerDetails.person : undefined
        remoteUid: telephony.primaryCallerDetails ? telephony.primaryCallerDetails.remoteUid : undefined
        enabled: telephony.silencedCall && telephony.primaryCall
        opacity: enabled ? 1.0 : 0.0

        Behavior on opacity { FadeAnimator {}}

        onClicked: {
            // update state, but prefer primary call
            telephony.preferPrimaryCall = true
            telephony.updateState()
        }
        //: Shown on a tappable green banner representing the active call,
        //: next to the caller name or phone number
        //% "in progress"
        secondaryText: qsTrId("voicecall-bt-in_progress")
    }

    SilicaItem {
        id: content

        width: incomingCallView.width
        height: incomingCallView.height
        opacity: incomingCallView.active ? 1.0 : 0.0
        Behavior on opacity { FadeAnimator { duration: incomingCallView.active ? 200 : 350 } }

        Column {
            id: labelColumn

            x: Theme.horizontalPageMargin
            y: Theme.paddingLarge
            width: parent.width - 2 * x

            opacity: !(isLandscape && menuLoader.menuOpen) ? 1.0 : 0.0
            Behavior on opacity { FadeAnimator {} }

            Item {
                visible: callWaiting && active
                height: _callerItem.height
                width: parent.width
                Label {
                    id: ongoingLabel
                    //% "Call ongoing"
                    text: qsTrId("voicecall-la-call_ongoing")
                    color: callingView.answerHighlightColor
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                }

                states: State {
                    when: ongoingLabel.visible
                    PropertyChanges { target: _callerItem; width: incomingCallView.width - ongoingLabel.width }
                }
            }

            Image {
                visible: forwarded
                anchors.horizontalCenter: parent.horizontalCenter
                source: "image://theme/icon-m-redirect"
            }

            Label {
                width: parent.width
                height: implicitHeight + Theme.paddingLarge
                truncationMode: TruncationMode.Fade
                horizontalAlignment: implicitWidth > width ? Text.AlignLeft : Text.AlignHCenter
                verticalAlignment: Text.AlignBottom
                font.pixelSize: Theme.fontSizeSmall
                color: palette.secondaryColor
                opacity: text.length > 0 ? 1.0 : 0.0
                text: telephony.simNameForCall(telephony.incomingCall || telephony.silencedCall)
            }

            Item { width: 1; height: Theme.paddingMedium }

            Label {
                id: firstNameLabel
                width: parent.width
                visible: text.length > 0
                horizontalAlignment: Text.AlignHCenter
                text: firstText.length > 0 || secondText.length > 0 ? firstText : CallHistory.formatNumber(phoneNumber)
                font { family: Theme.fontFamilyHeading; pixelSize: Theme.fontSizeHuge }
                elide: Text.ElideRight
                maximumLineCount: 2
                wrapMode: Text.Wrap
                bottomPadding: -Theme.paddingSmall
            }

            Label {
                text: secondText
                width: parent.width
                visible: text.length > 0
                horizontalAlignment: Text.AlignHCenter
                font { family: Theme.fontFamilyHeading; pixelSize: Theme.fontSizeHuge }
                elide: Text.ElideRight
                maximumLineCount: 2
                wrapMode: Text.Wrap
            }

            Item { width: 1; height: Theme.paddingMedium }

            FontMetrics {
                id: smallMetrics
                font.pixelSize: Theme.fontSizeSmall
            }

            Label {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Theme.fontSizeSmall
                color: palette.secondaryColor
                text: {
                    var details = []
                    var numberText = CallHistory.formatNumber(phoneNumber)
                    if (firstNameLabel.text !== numberText) {
                        details.push(numberText)
                    }

                    // Contact details
                    if (numberDetail.length > 0) {
                        details.push(numberDetail)
                    }

                    // Country indication
                    if (showCountry) {
                        details.push(phoneNumberParser.localizedCountryName)
                    }

                    // Determine wrapping
                    var pos = 0
                    var separators = []
                    for (var i = 0; i < details.length; i++) {
                        if (smallMetrics.advanceWidth(details.slice(pos, i + 1).join(" \u2022 ")) > width) {
                            pos = i
                            separators[i] = "\n" // wrap
                        } else {
                            separators[i] = " \u2022 " // separate with a bullet
                        }
                    }

                    // Compose the string
                    var text = details.length > 0 ? details[0] : ""
                    for (i = 1; i < details.length; i++) {
                        text = text + separators[i] + details[i]
                    }
                    return text
                }
            }
        }

        ListItem {
            id: menuLoader

            function open(title, menuComponent) {
                menuTitle.text = title
                menu = menuComponent
                var menuItem = openMenu()
                opacity = Qt.binding(function() { return menuItem.active ? 1.0 : 0.0})
            }


            enabled: false
            anchors.bottom: parent.bottom
            contentHeight: menuTitle.height + Theme.paddingLarge
            opacity: 0.0
            Behavior on opacity { FadeAnimation {} }

            Label {
                id: menuTitle

                font {
                    family: Theme.fontFamilyHeading
                    pixelSize: Theme.fontSizeLarge
                }

                x: Theme.horizontalPageMargin
                width: parent.width - 2*x

                color: palette.highlightColor
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
            }
        }
    }

    Messages.SmsSender {
        id: smsSender

        property bool sending
        onSendingSucceeded: sending = false
        onSendingFailed: sending = false
    }

    Component {
        id: messageReplyMenuComponent

        ContextMenu {
            id: messageReplyMenu

            SimPickerMenuItem {
                id: simPickerMenuItem
                menu: messageReplyMenu
                actionType: Telephony.Message
            }

            Repeater {
                model: QuickMessagesModel {
                    id: quickMessagesModel
                }

                MenuItem {
                    id: menuItem

                    text: model.display.replace(/\n/g, ' ')
                    enabled: !smsSender.sending
                    onClicked: {
                        var number = (main.state === "silenced" ? telephony.silencedCallerDetails.remoteUid : telephony.lastCaller)

                        if (telephony.promptForSim(number)) {
                            simPickerMenuItem.active = true
                            simPickerMenuItem.simSelected.connect(function(sim, modemPath) {
                                menuItem.sendMessage(modemPath, number)
                            })
                        } else {
                            menuItem.sendMessage(telephony.simManager.activeModem, number)
                        }
                    }

                    function sendMessage(modemPath, number) {
                        smsSender.sending = true
                        main.hangupAnimation.complete()
                        smsSender.sendSMS(modemPath, number, model.display)

                        // If the call is silenced, hang up, otherwise it's already ended, so no need to do anything
                        if (main.state === "silenced") {
                            telephony.hangupCall(telephony.silencedCall)
                            main.hangupAnimation.complete()
                        }
                    }
                }
            }

            MenuItem {
                //: Appears in the message reply menu which has limited space,
                //: opens the Messages app and allow the user to write a custom message.
                //% "Enter your message"
                text: qsTrId("voicecall-me-custom_message")
                onClicked: {
                    __window.lower() // make sure Phone app __window doesn't become active in-between and call callingDialog().activate()
                    main.callingView.lower() // JB#47779: Explicitly minimize the call dialog to make sure Messages comes on top
                    var number = (main.state === "silenced" ? telephony.silencedCallerDetails.remoteUid : telephony.lastCaller)
                    messaging.startSMS(number)
                    main.hangupAnimation.complete()
                }
            }
        }
    }

    Component {
        id: reminderMenuComponent

        ReminderContextMenu {
            id: reminderMenu

            number: main.state === "silenced"
                    ? telephony.silencedCallerDetails.remoteUid
                    : telephony.lastCaller
            person: main.state === "silenced"
                    ? telephony.silencedCallerDetails.person
                    : people.personByPhoneNumber(telephony.lastCaller)
        }
    }


    Component {
        id: multiCallMenuComponent

        ContextMenu {
            onClosed: {
                // Reset gestures so user is allowed to pick up or silence the call
                incomingCallView.resetGestures()
            }

            Label {
                //% "Answer and..."
                text: qsTrId("voicecall-la-answer_and")
                color: palette.highlightColor
                anchors.horizontalCenter: parent.horizontalCenter

                topPadding: Theme.paddingLarge
                bottomPadding: Theme.paddingLarge
            }
            MenuItem {
                //% "...hold ongoing"
                text: qsTrId("voicecall-me-hold_ongoing")
                onClicked: incomingCallView.answered()
            }
            MenuItem {
                //% "...end ongoing"
                text: qsTrId("voicecall-me-end_ongoing")
                onClicked: incomingCallView.endActiveAndAnswered()
            }
            Item {
                height: 2 * Theme.paddingLarge
            }
        }
    }

}
