.pragma library
.import org.nemomobile.contacts 1.0 as Contacts
.import Sailfish.Silica 1.0 as Silica
.import Sailfish.Contacts 1.0 as SailfishContacts

var CommonJs
var isInitialized = false

function init(common) // should be called by top-level contacts.qml
{
    if (isInitialized) {
        return
    }
    isInitialized = true

    CommonJs = common
}

function getDetailsActions(detailType)
{
    var actions = []
    var action = {}

    switch (detailType) {
    case "phone":
        actions.push({
            "actionIcon": "image://theme/icon-m-call",
            //% "Call"
            "actionLabel": qsTrId("components_contacts-action_call"),
            "actionType": "call"
        })

        actions.push({
            "actionIcon": "image://theme/icon-m-message",
            //% "SMS"
            "actionLabel": qsTrId("components_contacts-action_sms"),
            "actionType": "sms"
        })
        break

    case "email":
        actions.push({
            "actionIcon": "image://theme/icon-m-mail",
            //% "Send email"
            "actionLabel": qsTrId("components_contacts-action-email"),
            "actionType": "email"
        })
        break

    case "im":
        actions.push({
            "actionIcon": "image://theme/icon-m-message",
            //% "Send message"
            "actionLabel": qsTrId("components_contacts-action-im"),
            "actionType": "im"
        })
        break

    case "address":
        // we check every time so that it can update dynamically without requiring close+reopen of People app.
        if (SailfishContacts.ContactDetailActionHelper.handlerExistsForActionType("address")) {
            actions.push({
                "actionIcon": "image://theme/icon-m-location",
                //% "View on map"
                "actionLabel": qsTrId("components_contacts-action-view_on_map"),
                "actionType": "address"
            })
        } else {
            actions.push({
                "actionIcon": "image://theme/icon-m-location"
            })
        }
        break

    case "website":
        actions.push({
            "actionIcon": "image://theme/icon-m-website",
            //% "Open in browser"
            "actionLabel": qsTrId("components_contacts-action_open_in_browser"),
            "actionType": "website"
        })
        break

    case "date":
        actions.push({
            "actionIcon": "image://theme/icon-m-date",
            //% "Show date"
            "actionLabel": qsTrId("components_contacts-action-show_date"),
            "actionType": "date"
        })
        break

    case "note":
        actions.push({
            "actionIcon": "image://theme/icon-m-note"
        })
        break
    }

    return actions
}

function getContactCardDetailsModel(model, contact)
{
    if (!contact) {
        return
    }

    /**
     * This could probably be made more generic than this, but it might
     * not be needed to make just more complicated.
     */
    var details = []
    phoneDetails(details, contact)
    emailDetails(details, contact)
    imDetails(details, contact)
    addressDetails(details, contact)
    websiteDetails(details, contact)
    dateDetails(details, contact)
    noteDetails(details, contact)
    activityDetails(details, contact)

    var i
    var j
    var value
    var type

    // Remove any details no longer in the model
    j = 0
    for (i = 0; i < model.count; ) {
        value = model.get(i).detailsValue
        type = model.get(i).detailsType
        for (j = 0; j < details.length; ++j) {
            if (details[j].detailsValue == value && details[j].detailsType == type) {
                // We still have this detail in the model - update label and data in case they changed
                model.set(i, {
                    "detailsLabel": details[j].detailsLabel,
                    "detailsData": details[j].detailsData
                })
                break
            }
        }
        if (j == details.length) {
            model.remove(i, 1)
        } else {
            ++i
        }
    }

    // Add any details not yet in the model
    j = 0
    for (i = 0; i < details.length; ++i) {
        value = details[i].detailsValue
        type = details[i].detailsType
        for (j = 0; j < model.count; ++j) {
            if (model.get(j).detailsValue == value && model.get(j).detailsType == type) {
                // Already in the model
                break
            }
        }
        if (j == model.count) {
            if (i > model.count) {
                model.append(details[i])
            } else {
                model.insert(i, details[i])
            }
        }
    }
}

function getDetailMetadataForRemoteUid(contact, remoteUid)
{
    if (!contact) {
        return ""
    }

    var details = []
    phoneDetails(details, contact)
    fullPhoneDetails(details, contact)
    emailDetails(details, contact)
    imDetails(details, contact)

    for (var j = 0; j < details.length; ++j) {
        if (details[j].detailsValue == remoteUid) {
            return details[j].detailsLabel
        } else {
            var comparePhoneNumbers = [ remoteUid, details[j].detailsValue ]
            var minimized = contact.removeDuplicatePhoneNumbers(comparePhoneNumbers)
            if (minimized.length == 1) {
                return details[j].detailsLabel
            }
        }
    }

    return ""
}

//------------- internal helper functions

function phoneDetails(details, contact)
{
    var detail
    var minimizedNumbers = contact.removeDuplicatePhoneNumbers(contact.phoneDetails)
    for (var i = 0; i < minimizedNumbers.length; ++i) {
        detail = minimizedNumbers[i]
        details.push({
            "detailsType": "phone",
            "detailsLabel": CommonJs.getNameForDetailSubType(detail.type, detail.subTypes, detail.label),
            "detailsValue": detail.number,
            "detailsData": {}
        })
    }
}

function fullPhoneDetails(details, contact)
{
    var detail
    var fullNumbers = contact.phoneDetails
    for (var i = 0; i < fullNumbers.length; ++i) {
        detail = fullNumbers[i]
        details.push({
            "detailsType": "phone",
            "detailsLabel": CommonJs.getNameForDetailSubType(detail.type, detail.subTypes, detail.label),
            "detailsValue": detail.number,
            "detailsData": {}
        })
    }
}

function emailDetails(details, contact)
{
    var detail
    var emailDetails = contact.removeDuplicateEmailAddresses(contact.emailDetails)
    for (var i = 0; i < emailDetails.length; ++i) {
        detail = emailDetails[i]
        details.push({
            "detailsType": "email",
            "detailsLabel": CommonJs.getNameForDetailType(detail.type, detail.label),
            "detailsValue": detail.address,
            "detailsData": {}
        })
    }
}

function imDetails(details, contact)
{
    var nonvalidDetails = []
    var accountDetails = contact.removeDuplicateOnlineAccounts(contact.accountDetails)
    for (var i = 0; i < accountDetails.length; ++i) {
        var detail = accountDetails[i]
        var valid = detail.accountPath.length > 0
        var result = {
            "detailsType": (valid ? "im" : ""),
            "detailsLabel": CommonJs.getNameForImProvider(detail.serviceProviderDisplayName, detail.serviceProvider, detail.label),
            "detailsValue": detail.accountUri,
            "detailsData": (valid ? { 'localUid': detail.accountPath, 'remoteUid': detail.accountUri, 'presenceState': detail.presenceState } : {} )
        }
        if (valid) {
            // Order valid accounts before non-valid accounts
            details.push(result)
        } else {
            nonvalidDetails.push(result)
        }
    }
    for (i = 0; i < nonvalidDetails.length; ++i) {
        details.push(nonvalidDetails[i])
    }
}

function addressDetails(details, contact)
{
    for (var i = 0; i < contact.addressDetails.length; ++i) {
        var detail = contact.addressDetails[i]
        var addressParts = CommonJs.addressStringToMap(detail.address)
        details.push({
            "detailsType": "address",
            "detailsLabel": CommonJs.getNameForDetailSubType(detail.type, detail.subTypes, detail.label),
            "detailsValue": CommonJs.getAddressSummary(detail.address),
            "detailsData": {
                    "pobox": addressParts[Contacts.Person.AddressPOBoxField],
                    "street": addressParts[Contacts.Person.AddressStreetField],
                    "city": addressParts[Contacts.Person.AddressLocalityField],
                    "zipcode": addressParts[Contacts.Person.AddressPostcodeField],
                    "region": addressParts[Contacts.Person.AddressRegionField],
                    "country": addressParts[Contacts.Person.AddressCountryField]
                }
        })
    }
}

function websiteDetails(details, contact)
{
    for (var i = 0; i < contact.websiteDetails.length; ++i) {
        var detail = contact.websiteDetails[i]
        details.push({
            "detailsType": "website",
            "detailsLabel": CommonJs.getNameForDetailSubType(detail.type, detail.subType, detail.label),
            "detailsValue": detail.url,
            "detailsData": {}
        })
    }
}

function dateDetails(details, contact)
{
    var currentDetail = {}

    if (!isNaN(contact.birthday)) {
        details.push({
            "detailsType": "date",
            "detailsLabel": CommonJs.getNameForDetailType(Contacts.Person.BirthdayType, undefined),
            "detailsValue": Silica.Format.formatDate(contact.birthday, Silica.Format.DateLong),
            "detailsData": { "date": contact.birthday }
        })
    }
    for (var i = 0; i < contact.anniversaryDetails.length; ++i) {
        var detail = contact.anniversaryDetails[i]
        if (!isNaN(detail.originalDate)) {
            details.push({
                "detailsType": "date",
                "detailsLabel": CommonJs.getNameForDetailSubType(detail.type, detail.subType, undefined),
                "detailsValue": Silica.Format.formatDate(detail.originalDate, Silica.Format.DateLong),
                "detailsData": { "date": detail.originalDate }
            })
        }
    }
}

function noteDetails(details, contact)
{
    for (var i = 0; i < contact.noteDetails.length; ++i) {
        var detail = contact.noteDetails[i]
        details.push({
            "detailsType": "note",
            "detailsLabel": CommonJs.getNameForDetailType(Contacts.Person.NoteType, undefined),
            "detailsValue": detail.note,
            "detailsData": {}
        })
    }
}

function activityDetails(details, contact)
{
    var currentDetail = {}

    // Show activity if this contact has any phone or IM details
    for (var i = 0; i < details.length; ++i) {
        var type = details[i].detailsType
        if (type == "phone" || type == "im") {
            details.push({
                "detailsType": "activity",
                //% "Activity"
                "detailsLabel": qsTrId("components_contacts-la-activity"),
                //% "Past communication events"
                "detailsValue": qsTrId("components_contacts-la-activity_description")
            })
            return
        }
    }
}

