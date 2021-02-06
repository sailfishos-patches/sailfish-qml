import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0
import Sailfish.Lipstick 1.0
import com.jolla.settings 1.0
import org.nemomobile.lipstick 0.1

TabItem {
    id: page

    ApplicationsGrid {
        id: grid
        sectionHeaderVisible: false
        gridView.interactive: true
        gridView.height: page.height
        gridView.header: Column {
            width: page.width - (page.width - grid.gridView.width)/2
            Grid {
                id: partnerspaceGrid
                width: grid.gridView.width
                columns: {
                    if (Screen.sizeCategory < Screen.Large) {
                        return 1
                    } else if (page.orientation & (Orientation.Portrait | Orientation.PortraitInverted)) {
                        return 2
                    } else {
                        return 3
                    }
                }

                rowSpacing: Theme.paddingMedium

                Repeater {
                    id: partnerspaceRepeater

                    model: ApplicationSettingsModel {
                        applications: LauncherFolderModel {
                            scope: "partnerspace"
                            categories: "X-SailfishPartnerSpace"
                        }
                    }
                    BackgroundItem {
                        id: backgroundItem
                        width: partnerspaceGrid.width / partnerspaceGrid.columns

                        height: Theme.itemSizeMedium
                        enabled: model.section && (model.section.count(1) > 0
                                    || model.section.type == "page")

                        onClicked: grid.openSettings(model.name, model.section)

                        LauncherIcon {
                            id: appIcon
                            anchors {
                                left: parent.left
                                leftMargin: Theme.horizontalPageMargin
                                verticalCenter: parent.verticalCenter
                            }
                            opacity: backgroundItem.enabled ? 1 : Theme.opacityFaint
                            icon: model.iconId
                            pressed: backgroundItem.highlighted
                        }
                        Column  {
                            anchors.left: appIcon.right
                            anchors.leftMargin: Theme.paddingMedium
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            Label {
                                width: parent.width
                                color: backgroundItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                                font.pixelSize: Theme.fontSizeMedium
                                text: model.name
                                truncationMode: TruncationMode.Fade
                            }
                            Label {
                                width: parent.width
                                font.pixelSize: Theme.fontSizeExtraSmall
                                color: backgroundItem.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                                //% "Super app"
                                text: qsTrId("settings-la-super_app")
                                truncationMode: TruncationMode.Fade
                            }
                        }
                    }
                }
            }
            Item { width: 1; height: Theme.paddingMedium; visible: partnerspaceRepeater.count > 0 }
        }
    }
}
