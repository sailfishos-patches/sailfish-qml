import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0
import Sailfish.TextLinking 1.0
import org.pycage.jollastore 1.0

// collapsable details box
Expander {
    id: root

    property ApplicationData app
    horizontalMargin: Theme.horizontalPageMargin
    bottomMargin: Theme.paddingLarge

    collapsedHeight: lblSummary.y + Math.min(lblSummary.height, fontMetrics.height*6)
    expandedHeight: lblSummary.height + expandedDetails.height + Theme.paddingLarge

    width: parent.width

    FontMetrics {
        id: fontMetrics
        font: lblSummary.font
    }

    LinkedText {
        id: lblSummary
        y: Theme.paddingMedium
        x: horizontalMargin
        width: parent.width - 2*x
        plainText: app.summary + "\n\n" + app.description

        enabled: root.open
        color: highlighted ? Theme.highlightColor : Theme.primaryColor
        linkColor: enabled ? Theme.highlightColor : Theme.primaryColor
        font.pixelSize: Theme.fontSizeSmall
    }

    Column {
        id: expandedDetails

        x: horizontalMargin
        width: parent.width - 2*x
        anchors.top: lblSummary.bottom
        enabled: root.open

        Item { width: 1; height: Theme.paddingMedium * 2 }

        LinkedKeyValueLabel {
            visible: app.website !== ""
            //: Website label in application details box
            //% "Website"
            key: qsTrId("jolla-store-la-details_website")
            value: app.website
        }

        LinkedKeyValueLabel {
            visible: app.openSourceLink !== "" && app.openSourceLink !== app.website
            //: Open source link label in application details box
            //% "Source"
            key: qsTrId("jolla-store-la-details_open_source_link")
            value: app.openSourceLink
        }

        KeyValueLabel {
            visible: app.inStore
            //: Type label in application details box
            //: The value can be either Sailfish or Android application
            //: (jolla-store-la-sailfish_app or jolla-store-la-android_app, respectively)
            //% "Type"
            key: qsTrId("jolla-store-la-details_type")
            value: app.androidApp
            //% "Android application"
                   ? qsTrId("jolla-store-la-android_app")
                     //% "Sailfish application"
                   : qsTrId("jolla-store-la-sailfish_app")
        }

        KeyValueLabel {
            //: Version label in application details box
            //% "Version"
            key: qsTrId("jolla-store-la-details_version")
            value: normalizeVersion(app.version)
        }

        KeyValueLabel {
            visible: app.size > 0
            //: Size label in application details box
            //% "Size"
            key: qsTrId("jolla-store-la-details_size")
            value: Format.formatFileSize(app.size)
        }

        KeyValueLabel {
            visible: app.packageInstalled
            //: Version label of currently installed version
            //: in application details box
            //% "Installed"
            key: qsTrId("jolla-store-la-details_installed_version")
            value: normalizeVersion(packageHandler.packageVersion(app.packageName))
        }

        KeyValueLabel {
            visible: app.changes !== ""
            //: Changes label in application details box
            //% "Changes"
            key: qsTrId("jolla-store-la-details_changes")
            value: app.changes
        }

        KeyValueLabel {
            visible: app.inStore
            //: Updated label in application details box
            //% "Updated"
            key: qsTrId("jolla-store-la-details_updated")
            value: Format.formatDate(app.updatedOn, Formatter.Timepoint)
        }

        KeyValueLabel {
            visible: app.inStore
            //: Released label in application details box
            //% "Released"
            key: qsTrId("jolla-store-la-details_released")
            value: Format.formatDate(app.createdOn, Formatter.Timepoint)
        }

        //  TODO: Uncomment once the "requirements" are really used
        /*
            KeyValueLabel {
                visible: app.inStore
                //: Requires access label in application details box
                //% "Requires access to:"
                key: qsTrId("jolla-store-la-details_requires_access")
                //: No access requirements value text
                //% "None"
                value: app.requirements === "" ? qsTrId("jolla-store-va-details_no_requirements")
                                               : app.requirements

            }
            */
    }
}
