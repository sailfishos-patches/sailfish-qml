import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: root
    property var model
    property bool emojisEnabled

    Notice {
        id: systemNotification
        //: System notification advising user who is trying to disable all the keyboard layouts
        //% "You must have at least one keyboard selected"
        text: qsTrId("settings_text_input-he-warning_too_few_keyboards")
    }

    SilicaListView {
        anchors.fill: parent
        header: PageHeader {
            //: Page header in enabled keyboards settings page
            //% "Keyboards"
            title: qsTrId("settings_text_input-he-enabled_keyboards")
        }
        model: root.model
        delegate: TextSwitch {
            width: ListView.view.width
            height: Theme.itemSizeSmall
            text: qsTrId(name)

            checked: root.model.get(index).enabled
            automaticCheck: false
            onClicked: {
                if (checked && root.model.enabledCount === 1) {
                    systemNotification.show()
                } else if (checked && layoutModel.enabledCount === 2
                           && emojisEnabled && type !== "emojis") {
                    systemNotification.show()
                } else {
                    checked = !checked
                    root.model.setEnabled(index, checked)
                }
            }
        }

        VerticalScrollDecorator {}
    }
}
