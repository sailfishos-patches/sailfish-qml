import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    property int horizPageMargin: {
        if (Theme.horizontalPageMargin) return Theme.horizontalPageMargin
        else return Theme.paddingLarge
    }

    function setLangComboBox() {
        switch(settings.lang){
            case "bs":    return 1
            case "da":    return 2
            case "de":    return 3
            case "en":    return 4
            case "fr":    return 5
            case "zh_CN": return 6
            case "zh_TW": return 7
            case "hy":    return 8
            case "it":    return 9
            case "hu":    return 10
            case "no":    return 11
            case "pt_BR": return 12
            case "pt":    return 13
            case "ro":    return 14
            case "ru":    return 15
            case "sl":    return 16
            case "fi":    return 17
            case "sv":    return 18
            case "vi":    return 19
            case "uk":    return 20
            default:      return 0
        }
    }

    function setTempUnitComboBox() {
        switch(settings.tempUnit){
            case "F": return 1
            default:  return 0
        }
    }

    SilicaListView {
        anchors.fill: parent
        header: PageHeader {
            title: qsTrId("action_settings") + lcs.emptyString
        }

        model: VisualItemModel {
            ComboBox {
                label: {
                    var res = qsTrId("settings_itemtitle_language") + lcs.emptyString
                    if (res !== "Language") return res + " (Language)"
                    return res
                }
                menu: ContextMenu {
                    MenuItem {
                        text: qsTrId("value_default") + lcs.emptyString
                        onClicked: settings.lang = "0"
                    }
                    MenuItem {
                        text: "Bosanski"
                        onClicked: settings.lang = "bs"
                    }
                    MenuItem {
                        text: "Dansk"
                        onClicked: settings.lang = "da"
                    }
                    MenuItem {
                        text: "Deutsch"
                        onClicked: settings.lang = "de"
                    }
                    MenuItem {
                        text: "English"
                        onClicked: settings.lang = "en"
                    }
                    MenuItem {
                        text: "Français"
                        onClicked: settings.lang = "fr"
                    }
                    MenuItem {
                        text: "中文(简体)"
                        onClicked: settings.lang = "zh_CN"
                    }
                    MenuItem {
                        text: "中文(繁體)"
                        onClicked: settings.lang = "zh_TW"
                    }
                    MenuItem {
                        text: "Հայերեն"
                        onClicked: settings.lang = "hy"
                    }
                    MenuItem {
                        text: "Italiano"
                        onClicked: settings.lang = "it"
                    }
                    MenuItem {
                        text: "Magyar"
                        onClicked: settings.lang = "hu"
                    }
                    MenuItem {
                        text: "Norsk"
                        onClicked: settings.lang = "no"
                    }
                    MenuItem {
                        text: "Português (Brasil)"
                        onClicked: settings.lang = "pt_BR"
                    }
                    MenuItem {
                        text: "Português (Portugal)"
                        onClicked: settings.lang = "pt"
                    }
                    MenuItem {
                        text: "Română"
                        onClicked: settings.lang = "ro"
                    }
                    MenuItem {
                        text: "Pусский"
                        onClicked: settings.lang = "ru"
                    }
                    MenuItem {
                        text: "Slovenščina"
                        onClicked: settings.lang = "sl"
                    }
                    MenuItem {
                        text: "Suomi"
                        onClicked: settings.lang = "fi"
                    }
                    MenuItem {
                        text: "Svenska"
                        onClicked: settings.lang = "sv"
                    }
                    MenuItem {
                        text: "tiếng Việt"
                        onClicked: settings.lang = "vi"
                    }
                    MenuItem {
                        text: "Українська"
                        onClicked: settings.lang = "uk"
                    }
                }
                Component.onCompleted: currentIndex = setLangComboBox()
            }

            ComboBox {
                label: qsTrId("settings_itemtitle_tempunit") + lcs.emptyString
                menu: ContextMenu {
                    MenuItem {
                        text: "Celsius"
                        onClicked: settings.tempUnit = "C"
                    }
                    MenuItem {
                        text: "Fahrenheit"
                        onClicked: settings.tempUnit = "F"
                    }
                }
                Component.onCompleted: currentIndex = setTempUnitComboBox()
            }

            ListItem {
                contentHeight: uploadReport.height

                Column {
                    id: uploadReport
                    x: horizPageMargin
                    width: parent.width - 2 * x

                    Label {
                        text: qsTrId("settings_itemtitle_uploadreport") + lcs.emptyString
                        color: Theme.highlightColor
                        horizontalAlignment: Text.AlignRight
                        font.pixelSize: Theme.fontSizeSmall
                        width: parent.width
                        wrapMode: Text.Wrap
                    }

                    Item {
                      height: Theme.paddingSmall
                      width: 1
                    }

                    Label {
                        text: qsTrId("settings_itemdesc_uploadreport") + lcs.emptyString
                        color: Theme.primaryColor
                        horizontalAlignment: Text.AlignLeft
                        font.pixelSize: Theme.fontSizeSmall
                        width: parent.width
                        wrapMode: Text.Wrap
                    }
                }

                onClicked: pageStack.push(Qt.resolvedUrl("UploadReport.qml"))
            }
        }
    }
}
