import QtQuick 2.0
import Sailfish.Silica 1.0
import harbour.aida64.infopageloader 1.0

PullDownMenu {
    MenuItem {
        text: qsTrId("action_settings") + lcs.emptyString
        onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml"))
    }

    MenuItem {
        text: qsTrId("action_support") + lcs.emptyString
        onClicked: infopageloader.onClickHandler(InfoPageLoader.IIDENUM_ABOUT_SUPPORT)
    }

    MenuItem {
        text: qsTrId("action_save_report") + lcs.emptyString

        onClicked: {
            var fileName = infopageloader.saveReportToFile();

            if (fileName.length > 0) msgRect.showMessage(qsTrId("report_saved_to").replace("%s", "%1").
                                                         arg("\"" + fileName + "\"") + lcs.emptyString)
            else                     msgRect.showMessage("Cannot save report")
        }
    }

    MenuItem {
        text: qsTrId("action_report_in_email") + lcs.emptyString
        onClicked: infopageloader.sendReportInEmail(false)
    }

    MenuItem {
        text: qsTrId("action_report") + lcs.emptyString
        onClicked: infopageloader.sendReportInEmail(true)
    }
}
