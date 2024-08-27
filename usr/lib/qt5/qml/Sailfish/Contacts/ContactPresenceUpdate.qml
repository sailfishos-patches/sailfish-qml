import Nemo.DBus 2.0

/*!
  \inqmlmodule Sailfish.Contacts
*/
DBusInterface {
    // Request an update from the service implemented by commhistoryd
    service: "org.nemomobile.AccountPresence"
    path: "/org/nemomobile/AccountPresence"
    iface: "org.nemomobile.AccountPresenceIf"

    // 'state' should correspond to a member of SeasidePerson::PresenceState
    /*!
      See \l {Person::globalPresenceState} {Person.globalPresenceState} for possible values of \a state
     */
    function setGlobalPresence(state, message) {
        if (message !== undefined) {
            call('setGlobalPresenceWithMessage', [state, message])
        } else {
            call('setGlobalPresence', state)
        }
    }

    // 'accountPath' should be the canonical account path, as reported
    // by SeasidePerson.accountPaths
    function setAccountPresence(accountPath, state, message) {
        if (message !== undefined) {
            call('setAccountPresenceWithMessage', [accountPath, state, message])
        } else {
            call('setAccountPresence', [accountPath, state])
        }
    }
}
