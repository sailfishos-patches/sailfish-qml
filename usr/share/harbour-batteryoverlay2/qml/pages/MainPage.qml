import QtQuick 2.1
import Sailfish.Silica 1.0
import "../components"

Page {
    id: page
    objectName: "mainPage"

    property bool overlayRunning: false
    Connections {
        target: helper
        onOverlayRunning: {
            console.log("Received overlay pong")
            overlayRunning = true
        }
    }

    SilicaFlickable {
        id: flick
        anchors.fill: page
        contentHeight: content.height

        PullDownMenu {
            MenuItem {
                text: overlayRunning ? "Close overlay" : "Start overlay"
                onClicked: {
                    if (overlayRunning) {
                        overlayRunning = false
                        helper.closeOverlay()
                    }
                    else {
                        helper.startOverlay()
                    }
                }
            }

            MenuItem {
                text: "About"
                onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
            }
        }

        Column {
            id: content
            width: parent.width

            PageHeader {
                title: "Battery Overlay"
            }

            TextSwitch {
                text: "Follow orientation"
                checked: configuration ? configuration.followOrientation : false
                onClicked: configuration.followOrientation = checked
            }

            ComboBox {
                id: fixedOrientationCombo
                visible: !configuration.followOrientation
                label: "Fixed orientation:"
                menu: ContextMenu {
                    MenuItem { text: "top" }
                    MenuItem { text: "right" }
                    MenuItem { text: "bottom" }
                    MenuItem { text: "left" }
                }
                onCurrentIndexChanged: configuration.fixedOrientation = currentIndex
            }

            Slider {
                width: parent.width
                label: "Battery threshold"
                minimumValue: 1
                maximumValue: 100
                value: configuration ? configuration.threshold : 100
                valueText: parseInt(value) + "%"
                onReleased: configuration.threshold = parseInt(value)
            }

            Slider {
                width: parent.width
                label: "Line height"
                minimumValue: 1
                maximumValue: 20
                value: configuration ? configuration.lineHeight : 5
                valueText: parseInt(value) + "px"
                onReleased: configuration.lineHeight = parseInt(value)
            }

            Slider {
                width: parent.width
                label: "Global opacity"
                minimumValue: 1
                maximumValue: 100
                value: configuration ? configuration.opacityPercentage : 50
                valueText: parseInt(value) + "%"
                onReleased: configuration.opacityPercentage = parseInt(value)
            }

            TextSwitch {
                text: "Use system colors"
                checked: configuration ? configuration.useSystemColors : false
                onClicked: configuration.useSystemColors = checked
            }

            TextSwitch {
                text: "Apply gradient opacity fade"
                checked: configuration ? configuration.gradientOpacity : true
                onClicked: configuration.gradientOpacity = checked
            }

            ColorItem {
                title: "Charged color"
                selectedColor: configuration.normalChargedColor
                visible: !configuration.useSystemColors

                onClicked: {
                    var dialog = pageStack.push(Qt.resolvedUrl("ColorDialog.qml"), {"color": configuration.normalChargedColor})
                    dialog.accepted.connect(function() {
                        configuration.normalChargedColor = dialog.selectedColor
                    })
                }
            }

            ColorItem {
                title: "Uncharged color"
                selectedColor: configuration.normalUnchangedColor
                visible: !configuration.useSystemColors

                onClicked: {
                    var dialog = pageStack.push(Qt.resolvedUrl("ColorDialog.qml"), {"color": configuration.normalUnchangedColor})
                    dialog.accepted.connect(function() {
                        configuration.normalUnchangedColor = dialog.selectedColor
                    })
                }
            }

            TextSwitch {
                text: "Different colors for charging status"
                checked: configuration ? configuration.displayChargingStatus : false
                onClicked: configuration.displayChargingStatus = checked
            }

            ColorItem {
                title: "Charged color (charging)"
                selectedColor: configuration.chargingChargedColor
                visible: !configuration.useSystemColors && configuration.displayChargingStatus

                onClicked: {
                    var dialog = pageStack.push(Qt.resolvedUrl("ColorDialog.qml"), {"color": configuration.chargingChargedColor})
                    dialog.accepted.connect(function() {
                        configuration.chargingChargedColor = dialog.selectedColor
                    })
                }
            }

            ColorItem {
                title: "Uncharged color (charging)"
                selectedColor: configuration.chargingUnchargedColor
                visible: !configuration.useSystemColors && configuration.displayChargingStatus

                onClicked: {
                    var dialog = pageStack.push(Qt.resolvedUrl("ColorDialog.qml"), {"color": configuration.chargingUnchargedColor})
                    dialog.accepted.connect(function() {
                        configuration.chargingUnchargedColor = dialog.selectedColor
                    })
                }
            }
        }
    }

    property QtObject configuration
    Component.onCompleted: {
        configuration = Qt.createQmlObject("import org.nemomobile.configuration 1.0;" +
        "ConfigurationGroup {
            path: \"/apps/harbour-battery-overlay\"
            property bool followOrientation: false
            property int lineHeight: 5
            property int opacityPercentage: 50
            property string normalChargedColor: \"green\"
            property string normalUnchangedColor: \"red\"
            property string chargingChargedColor: \"cyan\"
            property string chargingUnchargedColor: \"blue\"
            property bool useSystemColors: false
            property bool displayChargingStatus: false
            property int fixedOrientation: 0
            property bool gradientOpacity: true
            property int threshold: 100
        }", page)

        fixedOrientationCombo._updating = false
        fixedOrientationCombo.currentIndex = configuration.fixedOrientation

        helper.checkOverlay();
    }
}
