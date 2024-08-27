import QtQuick 2.1
import Sailfish.Silica 1.0
import com.jolla.settings.system 1.0

Column {
    spacing: Theme.paddingLarge

    AboutText {
        //% "This product includes certain free/open source software. The exact terms of the related licenses, disclaimers, acknowledgements and notices are reproduced in the materials provided with this product. Jolla offers to provide you with the source code as defined in the applicable license. Please send a written request to:"
        text: qsTrId("settings_about-la-source_code_offer")
    }

    AboutText {
        text: "Jollyboys Ltd.<br>ATTN: Source Code Requests<br>Polttimonkatu 3<br>33210 Tampere<br>FINLAND"
    }

    AboutText {
        //% "This offer is valid for three years after the product has been made publicly available."
        text: qsTrId("settings_about-la-validity")
    }
}
