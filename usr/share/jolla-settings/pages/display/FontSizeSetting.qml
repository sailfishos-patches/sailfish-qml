import Nemo.Configuration 1.0

ConfigurationValue {
    readonly property string currentName: categoryNames[currentIndex]
    readonly property var categories: ["normal", "large", "huge"]
    readonly property int currentIndex: categories.indexOf(value)

    readonly property var categoryNames: [
        //% "Normal"
        qsTrId("settings_display-me-normal"),
        //% "Large"
        qsTrId("settings_display-me-large"),
        //% "Huge"
        qsTrId("settings_display-me-huge")
    ]

    function update(index) {
        var category = categories[index]
        if (category !== undefined) {
            value = categories[index]
        } else {
            console.warn("Trying to update font size setting with invalid category, index", index)
        }
    }

    key: "/desktop/jolla/theme/font/sizeCategory"
    defaultValue: "normal"
}
