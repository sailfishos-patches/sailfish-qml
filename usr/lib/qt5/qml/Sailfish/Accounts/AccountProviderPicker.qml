/****************************************************************************************
** Copyright (c) 2013 - 2023 Jolla Ltd.
** Copyright (c) 2020 Open Mobile Platform LLC.
**
** All rights reserved.
**
** This file is part of Sailfish Accounts components package.
**
** You may use this file under the terms of BSD license as follows:
**
** Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are met:
**
** 1. Redistributions of source code must retain the above copyright notice, this
**    list of conditions and the following disclaimer.
**
** 2. Redistributions in binary form must reproduce the above copyright notice,
**    this list of conditions and the following disclaimer in the documentation
**    and/or other materials provided with the distribution.
**
** 3. Neither the name of the copyright holder nor the names of its
**    contributors may be used to endorse or promote products derived from
**    this software without specific prior written permission.
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
** AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
** IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
** DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
** FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
** DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
** SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
** CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
** OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
** OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**
****************************************************************************************/

import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0

Column {
    id: root

    property var serviceFilter: []
    property var providerFilter: []
    property bool excludeProvidersForUncreatableAccounts

    signal providerSelected(int index, string providerName)

    //--- end of public api

    // List of account providers that are not in the other lists below.
    Repeater {
        model: ProviderModel {
            id: uncategorizedProviders

            serviceFilter: root.serviceFilter
            providerFilter: root.providerFilter
            excludeProvidersForUncreatableAccounts: root.excludeProvidersForUncreatableAccounts

            otherExcludedProviders: {
                // Don't show any providers already visible in the other two lists.
                var cloud = cloudProviders.providerNames
                var other = otherProviders.providerNames
                var excluded = []
                var i
                for (i = 0; i < cloud.length; ++i) {
                    excluded.push(cloud[i])
                }
                for (i = 0; i < other.length; ++i) {
                    excluded.push(other[i])
                }
                return excluded
            }
        }

        delegate: AccountProviderPickerDelegate {
            width: root.width
            onClicked: root.providerSelected(model.index, model.providerName)
        }
    }

    SectionHeader {
        //: List of account providers that offer cloud storage
        //% "Cloud storage"
        text: qsTrId("components_accounts-la-service_name_cloud_storage")
        visible: cloudProviders.count > 0
                && (uncategorizedProviders.count > 0 || otherProviders.count > 0)
    }

    // List of account providers that support storage services.
    Repeater {
        id: cloudStorageRepeater

        model: ProviderModel {
            id: cloudProviders

            serviceFilter: {
                if (root.serviceFilter.length > 0) {
                    // Don't use storage filter if it should be excluded according to root.serviceFilter
                    if (root.serviceFilter.indexOf("storage") < 0) {
                        return []
                    }
                }
                return ["storage"]
            }
            providerFilter: root.providerFilter
            otherExcludedProviders: otherProviders.providerNames
            excludeProvidersForUncreatableAccounts: root.excludeProvidersForUncreatableAccounts
        }

        delegate: AccountProviderPickerDelegate {
            width: root.width
            onClicked: root.providerSelected(model.index, model.providerName)
        }
    }

    SectionHeader {
        //: List of other types of account providers
        //% "Other"
        text: qsTrId("components_accounts-la-other")
        visible: otherProviders.count > 0
                 && (uncategorizedProviders.count > 0 || cloudProviders.count > 0)
    }

    // List of generic account providers.
    Repeater {
        id: otherRepeater

        model: ProviderModel {
            id: otherProviders

            serviceFilter: root.serviceFilter
            providerFilter: {
                var otherProviders = ["email", "onlinesync"]
                if (root.providerFilter.length > 0) {
                    // Remove any providers that should be filtered out according to providerFilter.
                    for (var i = 0; i < otherProviders.length; ++i) {
                        if (root.providerFilter.indexOf(otherProviders[i]) < 0) {
                            otherProviders.pop(i)
                        }
                    }
                }
                return otherProviders
            }
            excludeProvidersForUncreatableAccounts: root.excludeProvidersForUncreatableAccounts
        }

        delegate: AccountProviderPickerDelegate {
            width: root.width
            onClicked: root.providerSelected(model.index, model.providerName)
        }
    }

    ViewPlaceholder {
        enabled: uncategorizedProviders.count === 0
                 && cloudProviders.count === 0
                 && otherProviders.count === 0

        //% "No account providers available"
        text: qsTrId("components_accounts-la-no_account_providers_available")
    }
}
