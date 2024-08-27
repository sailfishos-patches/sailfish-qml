import QtQuick 2.1
import com.jolla.settings.system 1.0

Item {
    height: textItem.height

    AboutText {
        id: textItem
        text: "MPEG Layer-3. MPEG Layer-3 audio coding technology licensed from Fraunhofer IIS and Thomson Licensing. Supply of this product does not convey a license nor imply any right to distribute MPEG Layer-3 compliant content created with this product in revenue-generating broadcast systems (terrestrial, satellite, cable and/or other distribution channels), streaming applications (via Internet, intranets and/or other networks), other content distribution systems (pay-audio or audio-on-demand applications and the like) or on physical media (compact discs, digital versatile discs, semiconductor chips, hard drives, memory cards and the like). An independent license for such use is required. For details, please visit http://mp3licensing.com."
    }
}
