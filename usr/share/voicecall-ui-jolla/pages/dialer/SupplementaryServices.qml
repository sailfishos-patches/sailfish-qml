import QtQuick 2.0
import Sailfish.Silica 1.0
import QOfono 0.2

Item {
    id: root
    property alias modemPath: ofonoUSSD.modemPath
    property QtObject ssDialog
    property bool responsePending: ofonoUSSD.state === "user-response"

    function qsTrIdString() {
        //: Supplementary services basic service type
        //% "Voice"
        QT_TRID_NOOP("voicecall-la-ss_voice")
        //: Supplementary services basic service type
        //% "Data"
        QT_TRID_NOOP("voicecall-la-ss_data")
        //: Supplementary services basic service type
        //% "Fax"
        QT_TRID_NOOP("voicecall-la-ss_fax")
        //: Supplementary services basic service type
        //% "SMS"
        QT_TRID_NOOP("voicecall-la-ss_sms")
        //: Supplementary services basic service type
        //% "Data (sync)"
        QT_TRID_NOOP("voicecall-la-ss_datasync")
        //: Supplementary services basic service type
        //% "Data (async)"
        QT_TRID_NOOP("voicecall-la-ss_dataasync")
        //: Supplementary services basic service type
        //% "Data (PAD)"
        QT_TRID_NOOP("voicecall-la-ss_datapad")
        //: Supplementary services basic service type
        //% "Data (packet)"
        QT_TRID_NOOP("voicecall-la-ss_datapacket")
        //: Supplementary services status
        //% "Enabled"
        QT_TRID_NOOP("voicecall-la-ss_enabled")
        //: Supplementary services status
        //% "Disabled"
        QT_TRID_NOOP("voicecall-la-ss_disabled")
        //: Supplementary services status
        //% "On"
        QT_TRID_NOOP("voicecall-la-ss_on")
        //: Supplementary services status
        //% "Off"
        QT_TRID_NOOP("voicecall-la-ss_off")
        //: Supplementary services status
        //% "Permanent"
        QT_TRID_NOOP("voicecall-la-ss_permanent")
        //: Generic service message heading
        //% "Service Message"
        QT_TRID_NOOP("voicecall-he-ss_service_message")

        // Call forwarding
        //: Supplementary services forwarding service
        //% "Unconditional"
        QT_TRID_NOOP("voicecall-la-ss_unconditional")
        //: Supplementary services forwarding service
        //% "No reply"
        QT_TRID_NOOP("voicecall-la-ss_noreply")
        //: Supplementary services forwarding service
        //% "Busy"
        QT_TRID_NOOP("voicecall-la-ss_busy")
        //: Supplementary services forwarding service
        //% "Unreachable"
        QT_TRID_NOOP("voicecall-la-ss_notreachable")
        //: Supplementary services forwarding service
        //% "All"
        QT_TRID_NOOP("voicecall-la-ss_all")
        //: Supplementary services forwarding service
        //% "All conditional"
        QT_TRID_NOOP("voicecall-la-ss_allconditional")

        // Call barring
        //: Supplementary services barring service
        //% "All outgoing"
        QT_TRID_NOOP("voicecall-la-ss_alloutgoing")
        //: Supplementary services barring service
        //% "International outgoing"
        QT_TRID_NOOP("voicecall-la-ss_internationaloutgoing")
        //: Supplementary services barring service
        //% "International outgoing except home"
        QT_TRID_NOOP("voicecall-la-ss_internationaloutgoingexcepthome")
        //: Supplementary services barring service
        //% "All incoming"
        QT_TRID_NOOP("voicecall-la-ss_allincoming")
        //: Supplementary services barring service
        //% "Incoming when roaming"
        QT_TRID_NOOP("voicecall-la-ss_incomingwhenroaming")
        //: Supplementary services barring service
        //% "All barring services"
        QT_TRID_NOOP("voicecall-la-ss_allbarringservices")
        //: Supplementary services barring service
        //% "All outgoing services"
        QT_TRID_NOOP("voicecall-la-ss_alloutgoingservices")
        //: Supplementary services barring service
        //% "All incoming services"
        QT_TRID_NOOP("voicecall-la-ss_allincomingservices")
    }

    function initiateService(command) {
        if (!telephony.checkError()) {
            ofonoUSSD.initiate(command)
            var page = showServicePage()
            page.busy = true
        }
    }

    function serviceDialog() {
        if (!ssDialog) {
            var ssDialogComponent = Qt.createComponent("SupplementaryServiceMessage.qml")
            if (ssDialogComponent.status === Component.Ready) {
                ssDialog = ssDialogComponent.createObject(root, { "ofonoUSSD": ofonoUSSD })
                ssDialog.activeChanged.connect(function() {
                    if (!ssDialog.active) {
                        if (ofonoUSSD.state !== "idle") {
                            ofonoUSSD.cancel()
                        }
                    }
                })
            } else {
                console.log(ssDialogComponent.errorString())
            }
        }

        return ssDialog
    }

    function showServicePage(properties) {
        var page = serviceDialog()
        page.reset()
        for (var prop in properties) {
            page[prop] = properties[prop]
        }
        if (properties == undefined || !("title" in properties)) {
            page["title"] = qsTrId("voicecall-he-ss_service_message")
        }

        page.busy = false
        page.activate()

        return page
    }

    OfonoSupplementaryServices {
        id: ofonoUSSD

        property string lastState: "idle"

        function respondToService(command) {
            respond(command)
            var page = showServicePage()
            page.busy = true
        }
        function hidePendingPage() {
            if (ssDialog) {
                ssDialog.deactivate()
            }
        }

        function removeSuffix(prop, suffixes) {
            for (var s = 0; s < suffixes.length; s++) {
                var idx = prop.indexOf(suffixes[s])
                if (idx > -1) {
                    return prop.substring(0, idx)
                }
            }
            return prop
        }

        function translated(prop) {
            var strings = [
                        "Voice",
                        "Data",
                        "Fax",
                        "Sms",
                        "DataSync",
                        "DataAsync",
                        "DataPad",
                        "DataPacket",
                        "enabled",
                        "disabled",
                        "on",
                        "off",
                        "permanent",

                        // Call forwarding
                        "Unconditional",
                        "NoReply",
                        "Busy",
                        "NotReachable",
                        "All",
                        "AllConditional",

                        // Call barring
                        "AllOutgoing",
                        "InternationalOutgoing",
                        "InternationalOutgoingExceptHome",
                        "AllIncoming",
                        "IncomingWhenRoaming",
                        "AllBarringServices",
                        "AllOutgoingServices",
                        "AllIncomingServices"
                ]
            for (var s = 0; s < strings.length; s++) {
                if (prop === strings[s]) {
                    var trid = "voicecall-la-ss_" + prop.toLowerCase()
                    return qsTrId(trid)
                }
            }

            return prop
        }

        onStateChanged: {
            if (lastState === "user-response" && state == "idle") {
                // probably timed out
                hidePendingPage()
            }
            lastState = state
        }

        onNotificationReceived: {
            if (!ssDialog || !ssDialog.visible || message !== "") {
                showServicePage({ "message": message })
            }
        }
        onRequestReceived: showServicePage({ "message": message })
        onUssdResponse: showServicePage({ "message": response })

        onRespondComplete: {
            if (message.length > 0) {
                showServicePage({ "message": message })
            }
        }
        onInitiateFailed: {
            //% "Service request failed"
            var message = qsTrId("voicecall-la-ussd_failed")
            showServicePage({ "message": message })
        }
        onCancelComplete: hidePendingPage()
        onCallForwardingResponse: {
            //% "Call forwarding"
            var title = qsTrId("voicecall-he-call_forwarding")
            var props = {}
            var suffixes = [ "Unconditional", "Busy", "NoReply", "NotReachable", "All", "AllConditional" ]
            for (var fwd in cfMap) {
                if (fwd.indexOf("Timeout") > 0) {
                    continue
                }
                var value = translated(cfMap[fwd] === "" ? "disabled" : cfMap[fwd])
                var timeout = cfMap[fwd + "Timeout"]
                if (timeout !== undefined) {
                    //: No reply forwarding timeout. number | timeout, e.g. +61343443435 | 20s
                    //% "%1 | %ns"
                    value = qsTrId("voicecall-la-ss_notreachable_timeout", timeout).arg(value)
                }
                props[translated(removeSuffix(fwd, suffixes))] = value
            }
            showServicePage({ "title": title, "message": translated(cfService), "properties": props })
        }
        onCallBarringResponse: {
            //% "Call barring"
            var title = qsTrId("voicecall-he-call_barring")
            var props = {}
            var suffixes = [ "AllOutgoing", "InternationalOutgoing", "InternationalOutgoingExceptHome",
                          "AllIncoming", "IncomingWhenRoaming", "AllBarringServices", "AllOutgoingServices",
                          "AllIncomingServices" ]
            for (var barr in cbMap) {
                props[translated(removeSuffix(barr, suffixes))] = translated(cbMap[barr])
            }
            showServicePage({ "title": title, "message": translated(cbService), "properties": props })
        }
        onCallWaitingResponse: {
            //% "Call waiting"
            var title = qsTrId("voicecall-he-call_waiting")
            var props = {}
            var suffixes = [ "CallWaiting" ]
            for (var cw in cwMap) {
                props[translated(removeSuffix(cw, suffixes))] = translated(cwMap[cw])
            }
            showServicePage({ "title": title, "properties": props })
        }
        onCallingLinePresentationResponse: {
            //% "Calling line presentation"
            var title = qsTrId("voicecall-he-calling_line_presentation")
            showServicePage({ "title": title, "message": translated(status) })
        }
        onConnectedLinePresentationResponse: {
            //% "Connected line presentation"
            var title = qsTrId("voicecall-he-connected_line_presentation")
            showServicePage({ "title": title, "message": translated(status) })
        }
        onCallingLineRestrictionResponse: {
            //% "Calling line restriction"
            var title = qsTrId("voicecall-he-calling_line_restriction")
            showServicePage({ "title": title, "message": translated(status) })
        }
        onConnectedLineRestrictionResponse: {
            //% "Connected line restriction"
            var title = qsTrId("voicecall-he-connected_line_restriction")
            showServicePage({ "title": title, "message": translated(status) })
        }
    }
}
