/*
 * Copyright (c) 2013 - 2019 Jolla Pty Ltd.
 * Copyright (c) 2019 - 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
*/
import QtQuick 2.0
import Sailfish.Silica 1.0
import org.nemomobile.contacts 1.0

Page {
    id: root

    property Person person
    property var peopleModel

    property bool _busy

    // These are only used when aggregating multiple contacts selected from the ContactsMultiSelectDialog.
    property var _pendingAggregations: []
    property int _pendingAggregationCount

    function _runPendingAggregations() {
        _pendingAggregationCount = _pendingAggregations.length
        for (var i = 0; i < _pendingAggregations.length; ++i) {
            if (_pendingAggregations[i] === person.id) {
                // Ignore, cannot aggregate a contact into itself
                _pendingAggregationCount--
                continue
            }

            var aggregate = peopleModel.personById(_pendingAggregations[i])
            if (aggregate) {
                _busy = true
                aggregate.aggregateInto(person)
            }
        }
    }

    onStatusChanged: {
        if (status === PageStatus.Active && _pendingAggregations.length > 0) {
            _runPendingAggregations()
        }
    }

    ConstituentModel {
        id: constituentModel

        person: root.person
    }

    MergeCandidateModel {
        id: mergeCandidateModel

        person: root.person
    }

    Connections {
        target: root.person

        onAggregationOperationFinished: {
            root._busy = false
            _pendingAggregationCount = Math.max(0, _pendingAggregationCount - 1)
            if (_pendingAggregationCount === 0) {
                _pendingAggregations = []
            }
        }
    }

    SilicaListView {
        id: mainListView

        anchors.fill: parent
        opacity: 1 - busyLabel.opacity

        header: Column {
            width: parent.width

            PageHeader {
                //: Header for page enabling management of links (associated contacts with similar details) for this contact
                //% "Links"
                title: qsTrId("components_contacts-he-links")
            }

            Column {
                property real _prevHeight: height

                width: parent.width

                onHeightChanged: {
                    // Default ListView behavior pushes the header upwards and out of sight, so
                    // move it back down to ensure the header is visible when page is loaded.
                    var delta = (height - _prevHeight)
                    _prevHeight = height
                    if (delta > 0) {
                        mainListView.contentY -= delta
                    }
                }

                Repeater {
                    model: constituentModel

                    delegate: ContactLinkItem {
                        icon.source: "image://theme/icon-m-remove"
                        contactPrimaryName: model.primaryName
                        contactSecondaryName: model.secondaryName
                        addressBook: model.addressBook

                        // Disallow removing all constituents from an aggregate
                        enabled: constituentModel.count > 1

                        onClicked: {
                            if (root._busy) {
                                return
                            }
                            var constituent = root.peopleModel.personById(model.id)
                            if (constituent) {
                                root._busy = true
                                animateRemoval()
                                constituent.disaggregateFrom(root.person)
                            }
                        }
                    }
                }
            }

            SectionHeader {
                //: List of contacts with similar details that could be linked to this contact
                //% "Similar contacts"
                text: qsTrId("components_contacts-la-similar_contacts")
            }

            InfoLabel {
                //: Could not find any contacts with similar details to this one
                //% "No similar contacts found"
                text: qsTrId("components_contacts-la-no_similar_contacts_found")
                font.pixelSize: Theme.fontSizeMedium
                visible: mergeCandidateModel.populated && mergeCandidateModel.count === 0
            }
        }

        model: mergeCandidateModel

        delegate: ContactLinkItem {
            icon.source: "image://theme/icon-m-add"
            contactPrimaryName: model.primaryName
            contactSecondaryName: model.secondaryName
            addressBook: model.addressBook

            onClicked: {
                if (root._busy) {
                    return
                }
                var aggregate = root.peopleModel.personById(model.id)
                if (aggregate) {
                    root._busy = true
                    animateRemoval()
                    aggregate.aggregateInto(root.person)
                }
            }
        }

        PullDownMenu {
            MenuItem {
                //: Allows user to choose more contacts to be linked to this one
                //% "Add more links"
                text: qsTrId("components_contacts-me-add_links")
                enabled: !root._busy

                onClicked: {
                    var obj = pageStack.animatorPush(Qt.resolvedUrl("ContactsMultiSelectDialog.qml"))
                    obj.pageCompleted.connect(function(picker) {
                        picker.accepted.connect(function() {
                            root._pendingAggregations = picker.selectedContacts.allContactIds()
                            root._pendingAggregationCount = root._pendingAggregations.length
                        })
                    })
                }
            }
        }

        VerticalScrollDecorator {}
    }

    BusyLabel {
        id: busyLabel

        running: root._pendingAggregationCount > 0
                 || (!constituentModel.populated && !mergeCandidateModel.populated)
                 || root.status !== PageStatus.Active
    }
}
