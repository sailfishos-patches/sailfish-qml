import QtQuick 2.1
import com.jolla.settings.system 1.0

Item {
    height: textItem.height

    AboutText {
        id: textItem
        text: TextFileReader.collate(
                  Qt.resolvedUrl("500-ambience-licenses"),
                  "<br>",
                  qsTrId("settings_system-la_photos_and_ambience_general") +
                  " Creative Commons, Attribution 2.0 Generic (CC BY 2.0), https://creativecommons.org/licenses/by/2.0/<br>" +
                  qsTrId("settings_system-la_photos_have_been_modified") + "<br>")
    }
}
