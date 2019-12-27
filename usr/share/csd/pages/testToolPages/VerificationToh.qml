/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Csd 1.0
import ".."

CsdTestPage {
    id: page

    Column {
        width: page.width

        CsdPageHeader {
            //% "TOH"
            title: qsTrId("csd-he-toh")
        }

        Label {
            wrapMode: Text.Wrap
            x: Theme.paddingLarge
            width: parent.width - 2*Theme.paddingLarge
            color: Theme.highlightColor
            //% "Tests TOH cover detection and identification. Attach a TOH enabled cover."
            text: qsTrId("csd-la-toh_instructions")
        }

        Label {
            x: Theme.paddingLarge
            width: parent.width - 2*Theme.paddingLarge
            wrapMode: Text.Wrap
            text: {
                if (!toh.docked) {
                    //% "Cover is not attached"
                    return qsTrId("csd-la-cover_not_attached")
                } else if (!toh.ready) {
                    //% "Scanning..."
                    return qsTrId("csd-la-scanning")
                } else if (toh.tohId === "") {
                    //% "No tag found"
                    return qsTrId("csd-la-tag_not_found")
                } else {
                    //% "TOH detected and identified"
                    return qsTrId("csd-la-toh_identified")
                }
            }
        }

        Label {
            x: Theme.paddingLarge
            color: toh.passed ? "green" : "red"
            //% "Pass"
            text: toh.passed ? qsTrId("csd-la-pass")
                               //% "Fail"
                             : qsTrId("csd-la-fail")
        }

        SectionHeader {
            //% "TOH status information"
            text: qsTrId("csd-he-toh_status_information")
        }

        Row {
            x: Theme.paddingLarge
            spacing: Theme.paddingSmall

            Label {
                //% "Cover state:"
                text: qsTrId("csd-la-cover_state")
            }

            Label {
                //% "attached"
                text: toh.docked ? qsTrId("csd-la-attached")
                                   //% "detached"
                                 : qsTrId("csd-la-detached")
            }
        }

        Row {
            x: Theme.paddingLarge
            spacing: Theme.paddingSmall

            Label {
                //% "TOH state:"
                text: qsTrId("csd-la-toh_state")
            }

            Label {
                //% "ready"
                text: toh.ready ? qsTrId("csd-la-ready")
                                  //% "not ready"
                                : qsTrId("csd-la-not_ready")
            }
        }

        Label {
            x: Theme.paddingLarge
            //% "TOH Id: %1"
            text: qsTrId("csd-la-toh_id").arg(toh.tohId)
        }
    }


    Toh {
        id: toh

        property bool passed: toh.docked && toh.ready && toh.tohId !== ""
        onPassedChanged: check()

        function check() {
            setTestResult(toh.passed)
            testCompleted(false)
        }
    }

    Timer {
        id: timer
        interval: 1000
        running: true
        onTriggered: toh.check()
    }
}
