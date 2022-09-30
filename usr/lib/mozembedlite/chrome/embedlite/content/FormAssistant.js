/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 *
 * Copyright (c) 2021 Open Mobile Platform LLC.
 */

"use strict";

var globalObject = null;

function debug(msg) {
  Logger.debug("FormAssistant.js -", msg);
}

XPCOMUtils.defineLazyModuleGetters(this, {
  Services: "resource://gre/modules/Services.jsm",
});

/**
  * FormAssistant
  *
  * Checks the focussed form element to see whether it's the username field
  * of a login form for which login information has been stored. If it is the
  * relevant login usernames are sent to the UI for presentation to the user.
  *
  * The FormAssistant equivalent in Android also performs general autocomplete
  * functions, but we don't support those yet. Maybe in the future.
  *
  * Modified from LoginManagerContent.jsm (now LoginManagerChild.jsm)
  * See gecko-dev/mobile/android/modules/FormAssistant.jsm
  */
FormAssistant.prototype = {
  QueryInterface: ChromeUtils.generateQI([Ci.nsIObserver,
                                          Ci.nsISupportsWeakReference]),

  // Weak-ref used to keep track of the currently focused element.
  _currentFocusedElement: null,

  _init: function() {
    Logger.debug("JSScript: FormAssistant.js loaded");
    addEventListener("focus", this, true);
    addEventListener("blur", this, true);
    addEventListener("click", this, false);
    addEventListener("input", this, false);
  },

  get focusedElement() {
    return this._currentFocusedElement && this._currentFocusedElement.get();
  },

  handleEvent: function(aEvent) {
    switch (aEvent.type) {
      case "focus": {
        let currentElement = aEvent.target;
        // Only show suggestions on focus
        if (this._isAutoComplete(currentElement)) {
          this._currentFocusedElement = Cu.getWeakReference(currentElement);
        }
        break;
      }

      case "blur": {
        let focused = this.focusedElement;
        if (focused) {
          this._hideFormAssist(focused);
        }
        this._currentFocusedElement = null;
        break;
      }

      case "click": {
        let currentElement = aEvent.target;
        if (currentElement !== this.focusedElement) {
          break;
        }

        let checkResultsClick = hasResults => {
          if (!hasResults && currentElement === this.focusedElement) {
            this._hideFormAssist(currentElement);
          }
        };

        this._showAutoCompleteSuggestions(currentElement, checkResultsClick);
        break;
      }

      case "input": {
        let currentElement = aEvent.target;

        // If this element isn't focused, or its value hasn't changed,
        // don't show the suggestions
        if (currentElement !== this.focusedElement) {
          break;
        }

        // Prioritize login suggestions over other predictive text entries
        let checkResultsInput = hasResults => {
          if (hasResults || currentElement !== this.focusedElement) {
            return;
          }
          // If we're not showing login suggestions, hide the suggestions
          this._hideFormAssist(currentElement);
        };

        this._showAutoCompleteSuggestions(currentElement, checkResultsInput);
        break;
      }
    }
  },

  /**
    * _getAutoCompleteSuggestions
    *
    * Retrieves autocomplete suggestions for an element from the login manager.
    *
    * aSearchString -- current value of the input
    * aElement -- nsIDOMHTMLInputElement being autocompleted (may be null if from chrome)
    * aCallback(array_of_suggestions) is called when results are available.
    */
  _getAutoCompleteSuggestions: function(aSearchString, aElement, aCallback) {
    // Cache the form autocomplete service for future use
    if (!this._loginManager) {
      this._loginManager = Cc["@mozilla.org/login-manager;1"]
          .getService(Ci.nsILoginManager);
    }

    let hostname = aElement.baseURIObject.displayPrePath;
    let actionUri = LoginUtils._getActionOrigin(aElement);
    var suggestions = []
    // We only present suggestions if the form value is empty; this is so that:
    // 1. user selections will "replace" the full contents of the field; and
    // 2. we avoid synchronous search of the login database on every keypress.
    if (aElement.form && !aElement.value) {
      let foundLogins = this._loginManager.findLogins(hostname, actionUri, null);
      for (let pos = 0; pos < foundLogins.length; pos++) {
        // Filter suggestions based on the current input
        // Do not show the value if it is the current one in the input field
        if (foundLogins[pos].username.startsWith(aSearchString)
            && foundLogins[pos].username !== aSearchString) {
          suggestions.push(foundLogins[pos].username);
        }
      }
    }
    aCallback(suggestions);
  },

  /**
    * _showAutoCompleteSuggestions
    *
    * Retrieves autocomplete suggestions for an element from the login manager
    * and sends the suggestions to the UI.
    *
    * Calls aCallback when done with a true argument if results were found and
    * false if no results were found.
    *
    * aElement -- HTMLInputElement being autocompleted (may be null if from chrome)
    * aCallback(boolean_results_found) is called when results are available.
    */
  _showAutoCompleteSuggestions: function(aElement, aCallback) {
    if (!this._isAutoComplete(aElement)) {
      aCallback(false);
      return;
    }

    let resultsAvailable = suggestions => {
      // Return false if there are no suggestions to show
      if (!suggestions.length || aElement !== this.focusedElement) {
        aCallback(false);
        return;
      }

      let winId = Services.embedlite.getIDByWindow(aElement.ownerGlobal);
      Services.embedlite.sendAsyncMessage(winId, "FormAssist:AutoCompleteResult",
                                          JSON.stringify(suggestions));

      aCallback(true);
    };

    this._getAutoCompleteSuggestions(aElement.value, aElement, resultsAvailable);
  },

  /**
    * _hideFormAssist
    *
    * Hide the login suggestions from the UI. This is equivalent to
    * _hideFormAssistPopup() in FormAssistant.jsm
    */
  _hideFormAssist: function(aElement) {
    let winId = Services.embedlite.getIDByWindow(aElement.ownerGlobal);
    Services.embedlite.sendAsyncMessage(winId, "FormAssist:Hide", "[]");
  },

  // We only want to show login suggestions for certain elements
  _isAutoComplete: function(aElement) {
    return (ChromeUtils.getClassName(aElement) === "HTMLInputElement") &&
           !aElement.readOnly &&
           !this._isDisabledElement(aElement) &&
           (aElement.type !== "password") &&
           (aElement.autocomplete !== "off");
  },

  _isDisabledElement: function(aElement) {
    let currentElement = aElement;
    while (currentElement) {
      if (currentElement.disabled) {
        return true;
      }
      currentElement = currentElement.parentElement;
    }
    return false;
  },

};

/**
  * LoginUtils
  *
  * Allows extraction of origin information from form elements. These are
  * needed to identify any stored logins which relate to the form.
  *
  * Modified from LoginManagerContent.jsm (now LoginManagerChild.jsm)
  * See gecko-dev/toolkit/components/passwordmgr/LoginManagerContent.jsm
  */
var LoginUtils = {
  /**
   * Get the parts of the URL we want for identification.
   * Strip out things like the userPass portion
   */
  _getPasswordOrigin(uriString, allowJS) {
    var realm = "";
    try {
      var uri = Services.io.newURI(uriString);

      if (allowJS && uri.scheme == "javascript")
        return "javascript:";

      // Build this manually instead of using prePath to avoid including the userPass portion.
      realm = uri.scheme + "://" + uri.displayHostPort;
    } catch (e) {
      // bug 159484 - disallow url types that don't support a hostPort.
      // (although we handle "javascript:..." as a special case above.)
      log("Couldn't parse origin for", uriString, e);
      realm = null;
    }

    return realm;
  },

  _getActionOrigin(element) {
    let form = element.form;
    let formAction = element.formAction;
    var uriString = "";
    if (form && form.action) {
      uriString = form.action
    } else if (formAction) {
      uriString = formAction;
    }

    // A blank or missing action submits to where it came from.
    if (uriString == "")
      uriString = form.baseURI; // ala bug 297761

    return this._getPasswordOrigin(uriString, true);
  },
};

function FormAssistant() {
  this._init();
}

globalObject = new FormAssistant();
