import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import org.nemomobile.contacts 1.0
import com.jolla.settings.accounts 1.0
import com.jolla.settings.system 1.0
import org.nemomobile.systemsettings 1.0

Dialog {
    id: root

    property AccountManager accountManager

    property string username
    property string password
    property bool createAccountOnAccept: true
    property string acceptText
    property string cancelText

    property alias firstName: firstNameField.text
    property alias lastName: lastNameField.text
    property alias email: emailField.text
    property alias countryCode: countryButton.countryCode
    property alias countryName: countryButton.countryName
    property string languageLocale: languageModel.locale(languageModel.currentIndex)
    property var birthday: _selfPerson != null && _selfPerson.complete ? _selfPerson.birthday : undefined

    // Required for compatibility with jolla-store implementation.
    property Provider accountProvider
    property Item creationBusyDialog
    acceptDestination: creationBusyDialog
    onStatusChanged: {
        if (status == PageStatus.Inactive) {
            root.focus = true
        }
    }

    signal accountCreated(int newAccountId)
    signal accountCreationTypedError(int errorCode, string errorMessage)

    function createAccount() {
        accountFactory.createNewJollaAccount(
                    username,
                    password,
                    emailField.text,
                    firstNameField.text,
                    lastNameField.text,
                    birthday,
                    countryCode,
                    languageLocale,
                    "Jolla", "Jolla")
    }


    // --- end public api ---

    property bool checkMandatoryFields
    property Person _selfPerson
    property Person _selfPersonAggregate

    // Check that the email is basically in the format "blah@blah.com[...]", without any whitespace.
    // We don't want the regex to be too strict because a wide variety of characters are acceptable in an email address.
    property var _emailRegex: /^\S+@\S+\.\S+$/

    function _saveContactDetails() {
        var index = 0

        if (firstName.trim() !== "") {
            _selfPerson.firstName = firstName.trim()
        }
        if (lastName.trim() !== "") {
            _selfPerson.lastName = lastName.trim()
        }
        var myEmail = email.trim()
        if (myEmail !== "") {
            var emails = _selfPerson.emailDetails
            emails.push({
                'type': Person.EmailAddressType,
                'address': myEmail,
                'index': -1
            })
            _selfPerson.emailDetails = emails
        }
        if (birthday && !isNaN(birthday.getTime())) {
            _selfPerson.birthday = birthday
        }
        if (!peopleModel.savePerson(_selfPerson)) {
            console.log("Unable to save self contact details!")
        }
    }

    function _selectSelfPersonMultiValueField(details, property) {
        if (details.length === 0) {
            return ""
        }
        // We add our values last, with no label
        for (var i = details.length - 1; i >= 0; --i) {
            var detail = details[i]
            if (!detail.label || detail.label === Person.NoLabel) {
                return detail[property]
            }
        }
        // No detail matches, just return the last one
        return details[details.length - 1][property]
    }

    canAccept: firstNameField.text !== ""
               && lastNameField.text !== ""
               && !emailField.errorHighlight
               && languageLocale !== ""
               && birthdayButton.isOldEnough(birthday)

    onAccepted: {
        _saveContactDetails()
        if (createAccountOnAccept) {
            createAccount()
        }
    }

    onAcceptPendingChanged: {
        if (acceptPending === true) {
            checkMandatoryFields = true
        }
    }

    // Required for compatibility with jolla-store implementation.
    // It expects creationBusyDialog (an instance of AccountCreationBusyDialog) to be notified of
    // the account creation result.
    onAccountCreated: {
        if (creationBusyDialog != null) {
            creationBusyDialog.accountCreationSucceeded(newAccountId)
        }
    }
    onAccountCreationTypedError: {
        if (creationBusyDialog != null) {
            creationBusyDialog.accountCreationFailed(errorCode, errorMessage)
        }
    }

    PeopleModel {
        id: peopleModel

        onPopulatedChanged: {
            if (!root._selfPersonAggregate) {
                root._selfPersonAggregate = peopleModel.selfPerson()
                root._selfPersonAggregate.fetchConstituents()
            }
        }
    }

    Connections {
        target: root._selfPersonAggregate
        onConstituentsChanged: {
            if (root._selfPerson == null) {
                var constituents = root._selfPersonAggregate.constituents
                if (constituents.length === 0) {
                    console.warn("Cannot find constituent for self-contact")
                } else {
                    root._selfPerson = peopleModel.personById(constituents[0])
                }
            }
        }
    }

    AccountFactory {
        id: accountFactory

        onError: {
            console.log("JollaAccountCreationDialog error:", message)
            root.accountCreationTypedError(errorCode, message)
        }

        onSuccess: {
            root.accountCreated(newAccountId)
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: contentColumn.height

        Column {
            id: contentColumn
            width: parent.width

            DialogHeader {
                dialog: root
                acceptText: root.acceptText.length ? root.acceptText : defaultAcceptText
                cancelText: root.cancelText.length ? root.cancelText : defaultCancelText

                //: Description for page that requests user's name, email and other details in order to create a Jolla account
                //% "Almost done, we just need a few more details"
                title: qsTrId("settings_accounts-he-almost_done")

                // Ensure checkMandatoryFields is set if 'accept' is tapped and some fields
                // are not valid
                Item {
                    id: headerChild
                    Connections {
                        target: headerChild.parent
                        onClicked: root.checkMandatoryFields = true
                    }
                }
            }

            TextField {
                id: firstNameField
                width: parent.width

                //% "First name"
                label: qsTrId("settings_accounts-la-first_name")

                //% "Enter first name"
                placeholderText: qsTrId("settings_accounts-ph-first_name")

                text: root._selfPerson != null ? root._selfPerson.firstName : ""

                EnterKey.enabled: text || inputMethodComposing
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: lastNameField.focus = true
                errorHighlight: !text && checkMandatoryFields
            }

            TextField {
                id: lastNameField
                width: parent.width

                //% "Last name"
                label: qsTrId("settings_accounts-la-last_name")

                //% "Enter last name"
                placeholderText: qsTrId("settings_accounts-ph-last_name")

                text: root._selfPerson != null ? root._selfPerson.lastName : ""

                EnterKey.enabled: text || inputMethodComposing
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: emailField.focus = true
                errorHighlight: !text && checkMandatoryFields
            }

            TextField {
                id: emailField
                width: parent.width
                inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase | Qt.ImhEmailCharactersOnly
                validator: RegExpValidator { regExp: root._emailRegex }

                //% "Email address"
                label: qsTrId("settings_accounts-la-email")

                //% "Enter email address"
                placeholderText: qsTrId("settings_accounts-ph-email")

                text: root._selfPerson != null
                      ? root._selectSelfPersonMultiValueField(root._selfPerson.emailDetails, 'address')
                      : ""

                EnterKey.enabled: text || inputMethodComposing
                EnterKey.iconSource: "image://theme/icon-m-enter-close"
                EnterKey.onClicked: root.focus = true
                errorHighlight: (!text || !root._emailRegex.test(text)) && checkMandatoryFields
            }

            CountryValueButton {
                id: countryButton

                onCountrySelected: {
                    root.focus = true
                }
            }

            ValueButton {
                id: languageButton

                //: Allows language to be selected
                //% "Language"
                label: qsTrId("settings_accounts-la-language")
                // TODO: change hardcoded color to upcoming theme error color
                valueColor: languageLocale === "" && checkMandatoryFields
                            ? "#ff4d4d"
                            : Theme.highlightColor

                value: languageModel.languageName(languageModel.currentIndex)

                onClicked: {
                    root.focus = true
                    var obj = pageStack.animatorPush(languagePickerComponent)
                    obj.pageCompleted.connect(function(picker) {
                        picker.languageClicked.connect(function(language, locale) {
                            root.languageLocale = locale
                            languageButton.value = language
                            if (picker === pageStack.currentPage) {
                                pageStack.pop()
                            }
                        })
                    })
                }

                LanguageModel {
                    id: languageModel
                }

                Component {
                    id: languagePickerComponent
                    LanguagePickerPage {
                        languageModel: languageModel
                    }
                }
            }

            ValueButton {
                id: birthdayButton

                function isOldEnough(birthday) {
                    if (birthday == null || isNaN(birthday.getTime())) {
                        return false
                    }

                    var today = new Date()
                    var age = today.getFullYear() - birthday.getFullYear()
                    var months = today.getMonth() - birthday.getMonth()
                    if (months < 0 || (months === 0 && today.getDate() < birthday.getDate())) {
                        age--
                    }

                    return (age >= 13)
                }


                //: Allows birthday to be selected
                //% "Birthday"
                label: qsTrId("settings_accounts-la-birthday")
                // TODO: change hardcoded color to upcoming theme error color
                valueColor: !isOldEnough(root.birthday) && checkMandatoryFields
                            ? "#ff4d4d"
                            : Theme.highlightColor

                //% "If you are under 13 please contact customer support for more information."
                description: !isOldEnough(root.birthday) && checkMandatoryFields ? qsTrId("settings_accounts-la-age_disclaimer") : ""
                descriptionColor: "#ff4d4d"

                value: root.birthday != null && !isNaN(root.birthday.getTime())
                       ? Format.formatDate(root.birthday, Format.DateLong)
                         //% "Select your birthday"
                       : qsTrId("settings_accounts-bt-select_birthday")

                onClicked: {
                    root.focus = true
                    var defaultBirthday
                    if (root.birthday && !isNaN(root.birthday.getTime())) {
                        defaultBirthday = root.birthday
                    } else {
                        // set a sensible default birthday date rather than the current date
                        defaultBirthday = new Date()
                        defaultBirthday.setFullYear(defaultBirthday.getFullYear() - 20)
                    }
                    var obj = pageStack.animatorPush(datePickerComponent, { date: defaultBirthday, _showYearSelectionFirst: true })
                    obj.pageCompleted.connect(function(dialog) {
                        dialog.accepted.connect(function() {
                            root.birthday = dialog.date
                            birthdayButton.value = Format.formatDate(root.birthday, Format.DateLong)
                        })
                    })
                }

                Component {
                    id: datePickerComponent
                    DatePickerDialog {}
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - x*2
                height: implicitHeight + Theme.paddingLarge * 2
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.highlightColor

                //: Explains why it's necessary to ask for the user's birthday and country information when creating a Jolla account.
                //% "This information is needed to show appropriate content in the Jolla Store. "
                //% "Some apps or content may be age-restricted or only released in certain areas."
                text: qsTrId("settings_accounts-la-why_ask_for_personal_info")
            }
        }
    }
}
