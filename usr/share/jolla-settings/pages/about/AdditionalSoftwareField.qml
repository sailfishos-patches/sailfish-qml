import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Ssu 1.0

DetailItem {
    //% "Additional features"
    label: qsTrId("settings_about-la-additional_features")

    Component.onCompleted: load()
    function load() {
        var features = []
        if (featureModel.count > 0) {
            for (var i = 0; i < featureModel.count; i++) {
                var feature = featureModel.get(i)
                features[i] = feature.name + (feature.version.length > 0 ? " " + feature.version : "")
            }

            value = features.join(", ")
        } else {
            value = "-"
        }
    }
    Connections {
        target: Qt.application
        onActiveChanged: {
            if (Qt.application.active) {
                featureModel.reload()
                load()
            }
        }
    }
    FeatureModel {
        id: featureModel
    }
}
