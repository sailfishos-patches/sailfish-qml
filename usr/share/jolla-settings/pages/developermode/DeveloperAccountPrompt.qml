import QtQuick 2.0
import Sailfish.Silica 1.0
import com.jolla.settings.accounts 1.0
import org.nemomobile.systemsettings 1.0

Column {
    id: root

    property string accountProviderName
    property QtObject startingPage

    width: parent ? (parent.width - 2*Theme.horizontalPageMargin) : 0
    height: implicitHeight
    spacing: Theme.paddingLarge

    function _createAccount() {
        root.startingPage = pageStack.currentPage
        developerAccountSetup.startAccountCreationForProvider(
                    root.accountProviderName,
                    {},
                    PageStackAction.Animated)
    }

    Label {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        color: Theme.secondaryHighlightColor
        font.pixelSize: Theme.fontSizeLarge
        font.family: Theme.fontFamilyHeading
        text: root.accountProviderName == "jolla"
                //% "Developer mode requires a Jolla account"
              ? qsTrId("settings_developermode-la-requires_jolla_account")
                //% "Developer mode requires an account"
              : qsTrId("settings_developermode-la-requires_account")
    }

    Button {
        anchors.horizontalCenter: parent.horizontalCenter
        preferredWidth: Theme.buttonWidthMedium

        //% "Add Account"
        text: qsTrId("settings_developermode-bu-add_account")
        onClicked: root._createAccount()
    }

    AccountCreationManager {
        id: developerAccountSetup

        endDestination: root.startingPage
        endDestinationAction: PageStackAction.Pop
        endDestinationReplaceTarget: null
    }
}
