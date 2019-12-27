/*
 * Copyright (c) 2015 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQuick 2.2
import Sailfish.Silica 1.0
import Csd 1.0

TestCaseBaseItem {
    id: root

    property bool selected
    property bool showTestDurationSlider
    property alias currentSliderValue: testDurationSlider.sliderValue
    property alias sliderValue: testDurationSlider.value
    readonly property real passRateRequirement: CsdHwSettings.realValue(url.substr("Verification".length) + "/RunInTestPassRateRequirement" , 1.0)

    implicitHeight: textColumn.height + (showTestDurationSlider ? 1 : 2) * Theme.paddingMedium

    testStatusColor: {
        var ratio = 1 - failures / passes
        return ratio >= passRateRequirement ? "green" : "red"
    }

    Column {
        id: textColumn

        y: Theme.paddingMedium
        width: parent.width
        Row {
            x: Theme.horizontalPageMargin
            width: parent.width - 2*x
            Column {
                spacing: Theme.paddingMedium
                width: parent.width - Theme.paddingMedium - selectedIcon.width
                Label {
                    id: label
                    wrapMode: Text.Wrap
                    text: displayName
                    color: highlighted ? Theme.highlightColor : Theme.primaryColor
                    width: parent.width
                }
                Label {
                    id: resultCount

                    //% "Not executed"
                    text: untested ? qsTrId("csd-la-not-executed") :
                                     (//% "Pass"
                                      qsTrId("csd-la-pass") + ": " + passes +
                                      //% "Fail"
                                      " / " + qsTrId("csd-la-fail") + ": " + failures)
                    color: untested ? (highlighted ? Theme.secondaryHighlightColor: Theme.secondaryColor) : label.color
                    width: parent.width
                }
            }
            Image {
                id: selectedIcon
                visible: selected
                anchors.verticalCenter: parent.verticalCenter
                source: "image://theme/icon-s-certificates" + (root.highlighted ? "?" + Theme.highlightColor :  "")
            }
        }
        Slider {
            id: testDurationSlider

            enabled: showTestDurationSlider
            opacity: enabled ? 1.0 : 0.0
            height: enabled ? implicitHeight : 0
            width: parent.width

            Behavior on opacity { FadeAnimator { } }
            Behavior on height { NumberAnimation { } }

            minimumValue: 1
            maximumValue: 60
            stepSize: 1
            valueText: value

            //% "minutes"
            label: qsTrId("csd-la-runin_minutes")
        }
    }
}
