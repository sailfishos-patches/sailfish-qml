import QtQuick 2.0
import org.pycage.jollastore 1.0

QtObject {
    id: appData

    // the UUID that references the application
    property string application

    property bool inStore: true
    property string title
    property string company
    property string companyName
    property string user
    property string userName
    property string summary
    property string description
    property int rating
    property string downloads: "0"
    property int likes
    property string packageName
    property string collection
    property string version
    property string changes
    property string cover
    property string icon
    property string requirements
    property var screenshots: []
    property date createdOn
    property date updatedOn
    property date installedOn
    property string openSourceLink
    property string website
    property int size

    property int state: ApplicationState.Normal
    property int progress
    property bool packageInstalled: state === ApplicationState.Installed
                                    || state === ApplicationState.Updatable
                                    || state === ApplicationState.Updating

    // whether valid data was loaded
    property bool valid
    property string authorName: company !== "" ? companyName : userName
    property bool androidApp: packageName.indexOf("harbour-apk-") === 0

    property Connections connections: Connections {
        target: jollaStore

        onApplicationReceived: {
            if (uuid == application) {
                refresh()
            }
        }

        onCompanyReceived: {
            if (uuid === company) {
                refreshCompany()
            }
        }
    }

    property Connections packageConnections: Connections {
        target: packageHandler

        // note that usually there are very few (one) ApplicationData objects
        // alive at a time, so connecting to the signals should be no problem

        // monitor for app status changes
        onPackageStatusChanged: {
            if (packageName === appData.packageName) {
                appData.state = packageHandler.applicationState(appData.packageName, appData.version)
            }
        }

        // monitor for package progress changes
        onProgressChanged: {
            if (packageName === appData.packageName) {
                appData.progress = progress
            }
        }
    }

    property QtObject actions: AppActions {}

    property Timer timer: Timer {
        running: Qt.application.active
        interval: 10

        onTriggered: {
            refresh()
            running = false
        }
    }

    function install() {
        actions.install(application, packageName)
    }

    function update() {
        actions.update(application, packageName)
    }

    function uninstall() {
        actions.uninstall(application, packageName)
    }

    function refresh() {
        if (application === "")
            return

        console.log("Refreshing ApplicationData\n")

        var data = jollaStore.applicationData(application)
        if (data.hasOwnProperty("uuid")) {
            inStore = data.inStore
            title = data.title
            company = data.company
            user = data.user
            userName = data.userName
            summary = data.summary
            description = data.description
            rating = data.rating
            downloads = data.downloads
            likes = data.likes
            packageName = data.packageName
            collection = data.collection
            version = data.version
            changes = data.changes
            cover = data.cover
            icon = data.icon
            createdOn = data.createdOn
            updatedOn = data.updatedOn
            installedOn = data.installedOn
            requirements = data.requirements
            openSourceLink = data.openSourceLink
            website = data.website
            size = data.size

            state = packageHandler.applicationState(packageName, version)
            progress = packageHandler.packageProgress(packageName)

            if (data.screenshots !== "") {
                screenshots = data.screenshots.split(" ")
            } else {
                screenshots = []
            }
            valid = true
        }
    }

    function refreshCompany() {
        if (company === "")
            return

        var companyData = jollaStore.companyData(company)
        if (companyData.hasOwnProperty("uuid")) {
            companyName = companyData.name
        }
    }

    onApplicationChanged: {
        valid = false
        refresh()
    }
    onCompanyChanged: refreshCompany()
}

