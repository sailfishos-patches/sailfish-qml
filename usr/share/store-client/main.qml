import QtQuick 2.0
import Sailfish.Silica 1.0
import org.pycage.jollastore 1.0
import "cover"
import "pages"

ApplicationWindow {
    id: win

    property int _pageWidth: pageStack.currentPage ? pageStack.currentPage.width : width
    property bool _isPortrait: pageStack.currentPage ? pageStack.currentPage.isPortrait : true

    property int appGridMargin: Screen.sizeCategory > Screen.Medium ? Theme.horizontalPageMargin : 0
    property int appGridSpacing: Screen.sizeCategory > Screen.Medium ? Theme.paddingLarge : 0
    property int appGridColumns: _isPortrait ? 2 : 3
    property int appGridFontSize: Screen.sizeCategory > Screen.Medium ? Theme.fontSizeExtraSmall : Theme.fontSizeTiny
    property int appGridIconSize: Screen.sizeCategory > Screen.Medium ? Theme.iconSizeLauncher : Theme.iconSizeMedium
    property int maxAppGridColumns: 3

    property string _packageName
    property bool _signInPending

    // specifies where in the UI the user lands after signing in
    property string _uiEntryPoint
    property bool _storeAvailable: jollaStore.isOnline &&
                                   (jollaStore.connectionState === JollaStore.Ready ||
                                    jollaStore.connectionState === JollaStore.Connecting)

    signal uiOpened
    signal uiClosed
    signal showApp(string packageName)
    signal openInstalled
    signal enterStore
    signal systemDialogCreated
    signal systemDialogDestroyed

    allowedOrientations: Screen.sizeCategory > Screen.Medium
                         ? defaultAllowedOrientations
                         : defaultAllowedOrientations & Orientation.PortraitMask
    _defaultPageOrientations: Orientation.All
    _defaultLabelFormat: Text.PlainText

    /* Shows the UI depending on the given UI entry point.
     * Shows the sign in page if not already signed in.
     */
    function showEntryPoint(entryPoint) {
        console.log("Showing UI entry point " + entryPoint)

        if (!_storeAvailable) {
            _uiEntryPoint = entryPoint
            pushSignIn()
            return
        } else {
            _uiEntryPoint = ""
        }

        if (entryPoint === "app") {
            pushStore()
            pushDeeplink(_packageName)
        } else if (entryPoint === "store") {
            pushStore()
        } else if (entryPoint === "myapps") {
            pushStore()
            navigationState.openInstalled(true)
        } else {
            console.log("unknown UI entry point: " + entryPoint)
            pushStore()
        }
    }

    function pushStore() {
        if (pageStack.depth > 0) {
            var first = firstPage()
            if (first.objectName !== "WelcomePage") {
                pageStack.pop(first, PageStackAction.Immediate)
                pageStack.replace(welcomePage, {}, PageStackAction.Immediate)
            } else if (first !== pageStack.currentPage) {
                pageStack.pop(first, PageStackAction.Immediate)
            } // else -> already on first page
        } else {
            pageStack.push(welcomePage, {}, PageStackAction.Immediate)
        }
    }

    function pushDeeplink(packageName) {
        var props = {
            "packageName": packageName
        }

        pageStack.push(Qt.resolvedUrl("pages/DeeplinkPage.qml"), props,
                       PageStackAction.Immediate)
    }

    function pushSignIn() {
        if (pageStack.busy) {
            // we might notice that the credentials are lost in the middle of push/pop operation
            _signInPending = true
            return
        }
        if (pageStack.depth > 0) {
            if (pageStack.currentPage.objectName !== "SignInPage") {
                pageStack.pop(firstPage(), PageStackAction.Immediate)
                pageStack.replace(signInPage, {}, PageStackAction.Immediate)
            }
        } else {
            pageStack.push(signInPage, {}, PageStackAction.Immediate)
        }
    }

    function firstPage() {
        var first = pageStack.currentPage
        var temp = pageStack.previousPage(pageStack.currentPage)
        while (temp) {
            first = temp
            temp = pageStack.previousPage(temp)
        }
        return first
    }

    /* Returns the normalized version string to be shown to users.
     * This excludes the release number extensions (we don't use them for
     * version comparison either) and gives a cleaner look.
     */
    function normalizeVersion(version) {
        var idx = version.indexOf('-')
        return (idx === -1) ? version : version.substring(0, idx)
    }

    on_StoreAvailableChanged: {
        if (_storeAvailable) {
            if (_uiEntryPoint !== "") {
                showEntryPoint(_uiEntryPoint)
            }
        }
    }

    onUiOpened: {
        win.activate()
    }

    onUiClosed: {
        console.log("UI was closed")
        pageStack.clear()
        _uiEntryPoint = ""
    }

    onShowApp: {
        _packageName = packageName
        showEntryPoint("app")
    }

    onOpenInstalled: {
        showEntryPoint("myapps")
    }

    onEnterStore: {
        showEntryPoint("store")
    }

    AppGridItem {
        id: gridItemForSize
        width: Math.floor((_pageWidth -2 * appGridMargin - (appGridColumns - 1) * appGridSpacing) / appGridColumns)
        visible: false
    }

    QtObject {
        id: navigationState

        property int category
        property var openedInfoPanelRow

        function openApp(application, appState)
        {
            console.log("Open App " + application)

            var props = {
                "application": application
            }
            if (pageStack.currentPage.objectName === "AppPage") {
                pageStack.animatorReplace(Qt.resolvedUrl("pages/AppPage.qml"), props)
            } else {
                pageStack.animatorPush(Qt.resolvedUrl("pages/AppPage.qml"), props)
            }
        }

        function openCategory(category, topListType)
        {
            var props = { "title": jollaStore.categoryName(category),
                          "scope": "store",
                          "category": category,
                          "topListType": topListType }
            pageStack.animatorPush(Qt.resolvedUrl("pages/StorePage.qml"), props)
        }

        function openSearch(immediate)
        {
            var searchPage = pageStack.find(function(page) {
                return page.objectName === "SearchPage"
            })

            var actionType = immediate ? PageStackAction.Immediate : PageStackAction.Animated

            if (searchPage) {
                pageStack.pop(searchPage, actionType)
            } else {
                pageStack.animatorPush(Qt.resolvedUrl("pages/SearchPage.qml"), {}, actionType)
            }
        }

        function openAuthor(name, scope, filter)
        {
            var authorPage = pageStack.find(function(page) {
                return page.objectName === "StorePage" && page.filter === filter
            })

            if (authorPage) {
                pageStack.pop(authorPage)
            } else {
                var props = { "title": name,
                              "scope": scope,
                              "filter": filter }
                pageStack.animatorPush(Qt.resolvedUrl("pages/StorePage.qml"), props)
            }
        }

        function openReview(application, author, version)
        {
            var props = {
                "appUuid": application,
                "appAuthor": author,
                "packageVersion": version
            }
            pageStack.animatorPush(Qt.resolvedUrl("pages/ReviewsPage.qml"), props)
        }

        function openInstalled(immediate)
        {
            var installedPage = pageStack.find(function(page) {
                return page.objectName === "InstalledPage"
            })

            var actionType = immediate ? PageStackAction.Immediate : PageStackAction.Animated

            if (installedPage) {
                pageStack.pop(installedPage, actionType)
            } else {
                pageStack.animatorPush(Qt.resolvedUrl("pages/InstalledPage.qml"), {}, actionType)
            }
        }
    }

    Connections {
        target: jollaStore

        onSignUpRequired: {
            if (_uiEntryPoint === "") {
                _uiEntryPoint = "store"
            }
            pushSignIn()
        }
    }

    Connections {
        target: pageStack

        onBusyChanged: {
            if (_signInPending && !pageStack.busy) {
                _signInPending = false
                pushSignIn()
            }
        }
    }

    Component {
        id: welcomePage

        WelcomePage { }
    }

    Component {
        id: signInPage

        SignInPage { }
    }

    cover: CoverPage {
        id: coverPage

        onSearchActionTriggered: {
            win.activate()
            navigationState.openSearch(true)
        }
    }
}
