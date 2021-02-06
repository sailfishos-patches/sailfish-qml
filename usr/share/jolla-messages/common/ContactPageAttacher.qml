/*
 * Copyright (c) 2013 - 2020 Jolla Ltd.
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Messages 1.0

Item {
    property var people

    property Page basePage
    property Page page: null
    property Page placeholderPage: null

    property string attachedPageSource
    property var attachedPageProperties
    property var attachedPageComponent

    Component.onCompleted: {
        if (MessageUtils.attachedComponentCache === undefined) {
            MessageUtils.attachedComponentCache = {}
        }
    }

    onPeopleChanged: {
        if (basePage.status === PageStatus.Active || (page && (page.status === PageStatus.Active))) {
            updatePerson()
        }
    }

    Connections {
        target: basePage
        onStatusChanged: {
            if (basePage.status === PageStatus.Active) {
                updatePerson()
            }
        }
    }

    Connections {
        target: page
        onStatusChanged: {
            if (page.status === PageStatus.Active) {
                if (page.hasOwnProperty('recipients')) {
                    page.recipients = people
                } else if (page.hasOwnProperty('contact') && page.contact == null) {
                    page.contact = people[0].id === 0 ? people[0] : MessageUtils.peopleModel.personById(people[0].id)
                }
            }
        }
    }

    Connections {
        target: attachedPageComponent !== undefined ? attachedPageComponent : null
        onStatusChanged: {
            if (attachedPageComponent.status == Component.Error) {
                console.warn("Unable to create component:", attachedPageComponent.url, attachedPageComponent.errorString())
            }
        }
    }

    function createAttachedPageComponent(mode) {
        if (attachedPageComponent === undefined) {
            // Create the component from the mainWindow, so its parent context will not be destroyed
            attachedPageComponent = mainWindow.createComponent(attachedPageSource, mode)
            MessageUtils.attachedComponentCache[attachedPageSource] = attachedPageComponent
        }
    }

    Connections {
        target: placeholderPage
        onStatusChanged: {
            if (placeholderPage.status === PageStatus.Activating) {
                // Create the component to replace this page, if necessary
                createAttachedPageComponent(Component.Asynchronous)
            }
        }
    }

    property bool attachedPagePrepared: attachedPageComponent !== undefined && attachedPageComponent.status == Component.Ready &&
                                        placeholderPage !== null && placeholderPage.status == PageStatus.Active
    onAttachedPagePreparedChanged: {
        if (attachedPagePrepared) {
            pageSwitcher.restart()
        }
    }

    Timer {
        id: pageSwitcher
        interval: 0
        onTriggered: {
            // Replace the placeholder page with the real attached page
            pageStack.popAttached(undefined, PageStackAction.Immediate)
            createAttachedPageComponent(Component.PreferSynchronous)
            page = pageStack.pushAttached(attachedPageComponent.createObject(null, attachedPageProperties), {}, PageStackAction.Immediate)
            pageStack.navigateForward(PageStackAction.Immediate)
            fadeInAnimation.restart()
        }
    }

    FadeAnimation {
        id: fadeInAnimation
        target: page
        from: 0
        to: 1
    }

    function updatePerson() {
        if (people.length === 0
                   // Don't show contact card for a service/operator recipient without an actual phone number
                || (!conversation.hasPhoneNumber && conversation.message.isSMS)) {
            if (page) {
                if (basePage && basePage.pageContainer) {
                    pageStack.popAttached(basePage)
                }
                page = null
            }
            return
        }

        if (people.length > 1) {
            if (page === null || !page.hasOwnProperty('recipients')) {
                attachedPageSource = Qt.resolvedUrl("../RecipientsPage.qml")
                attachedPageProperties = { 'recipients': people }
            } else if (page !== null) {
                page.recipients = people
                return
            }
        } else {
            var person = people[0].id === 0 ? people[0] : MessageUtils.peopleModel.personById(people[0].id)
            if (page === null || !page.hasOwnProperty('contact')) {
                attachedPageSource = pageStack.resolveImportPage('Sailfish.Contacts.ContactCardPage')
                attachedPageProperties = {
                    'contact': person,
                    'activeDetail': conversation.message.remoteUids[0]
                }
            } else if (page !== null && page.contact == null) {
                page.contact = person
                return
            }
        }

        attachedPageComponent = MessageUtils.attachedComponentCache ? MessageUtils.attachedComponentCache[attachedPageSource] : undefined
        if (attachedPageComponent === undefined || attachedPageComponent.status !== Component.Ready) {
            placeholderPage = pageStack.pushAttached('AttachedPlaceholderPage.qml')
        } else {
            page = pageStack.pushAttached(attachedPageComponent.createObject(null, attachedPageProperties))
        }
    }
}

