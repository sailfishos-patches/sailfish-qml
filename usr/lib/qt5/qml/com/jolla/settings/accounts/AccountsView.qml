import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import Sailfish.Policy 1.0
import com.jolla.settings.system 1.0

SilicaFlickable {
    property alias accountsPage: logic.accountsPage
    property alias showHeader: header.visible

    Component.onCompleted: {
        if (!accountsPage) {
            var parentItem = this
            while (parentItem) {
                if (parentItem.hasOwnProperty("__silica_page")) {
                    accountsPage = parentItem
                    return
                }
                parentItem = parentItem.parent
            }
        }
    }

    anchors.fill: parent
    contentHeight: content.height

    VerticalScrollDecorator {}

    AccountsViewLogic {
        id: logic
        title: header.title
        model: accountsView.model
    }

    Column {
        id: content
        width: parent.width
        enabled: AccessPolicy.accountCreationEnabled

        PageHeader {
            id: header
            //: Heading of the main Accounts page
            //% "Accounts"
            title: qsTrId("settings_accounts-he-page_accounts")
        }

        DisabledByMdmBanner {
            active: !content.enabled
        }

        SectionHeader {
            //: Heading of sub-list of provisioned accounts (created by MDM)
            //% "Provisioned"
            text: qsTrId("components_accounts-he-provisioned")
            visible: provisionedAccountsView.model.count > 0
        }

        AccountsFlowView {
            id: provisionedAccountsView

            filterType: AccountModel.ProvisionedFilter
            filter: "true"
            visible: provisionedAccountsView.model.count > 0
            width: parent.width
            itemWidth: Screen.sizeCategory >= Screen.Large ? width/2 : width
            deletingAccountId: logic.deletingAccountId
            entriesInteractive: true

            onAccountClicked: logic.accountClicked(accountId, providerName)
            onAccountRemoveRequested: logic.accountRemoveRequested(accountId)
            onAccountSyncRequested: logic.accountSyncRequested(accountId)
        }

        SectionHeader {
            id: personalAccountsHeader
            //: Heading of sub-list of personal accounts (created by the user)
            //% "Personal"
            text: qsTrId("components_accounts-he-personal")
            visible: provisionedAccountsView.model.count > 0
        }

        AccountsFlowView {
            id: accountsView

            filterType: AccountModel.ProvisionedFilter
            filter: "false"
            width: parent.width
            itemWidth: Screen.sizeCategory >= Screen.Large ? width/2 : width
            deletingAccountId: logic.deletingAccountId
            entriesInteractive: true

            onAccountClicked: logic.accountClicked(accountId, providerName)
            onAccountRemoveRequested: logic.accountRemoveRequested(accountId)
            onAccountSyncRequested: logic.accountSyncRequested(accountId)

            ViewPlaceholder {
                enabled: provisionedAccountsView.model.count == 0 && accountsView.model.count == 0

                //: Viewplaceholder for no accounts, no pulley menu, only add account button
                //% "No accounts"
                text: qsTrId("components_accounts-he-no_accounts_no_pulley")
            }
        }

        BackgroundItem {
            id: addItem
            width: parent.width
            height: Theme.itemSizeMedium
            onClicked: logic.accountCreationManager.startAccountCreation()
            Image {
                id: icon
                x: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                source: "image://theme/icon-m-add" + (addItem.highlighted ? "?" + Theme.highlightColor : "")
            }
            Label {
                //: Initiates adding a new account
                //% "Add account"
                text: qsTrId("components_accounts-me-add_account")
                truncationMode: TruncationMode.Fade
                color: addItem.highlighted ? Theme.highlightColor : Theme.primaryColor
                anchors {
                    left: icon.right
                    leftMargin: Theme.paddingLarge
                    verticalCenter: parent.verticalCenter
                    right: parent.right
                    rightMargin: Theme.horizontalPageMargin
                }
            }
        }
    }
}
