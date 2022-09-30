/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 *
 * Copyright (c) 2021 Open Mobile Platform LLC.
 */

"use strict";

var gInputMethodHandler = null;

function debug(msg) {
  Logger.debug("InputMethodHandler.js -", msg);
}

XPCOMUtils.defineLazyModuleGetters(this, {
  Services: "resource://gre/modules/Services.jsm",
});

/**
  * InputMethodHandler
  *
  * Provides surrounding text, cursor and anchor position of editable
  * element for predictive input.
  */
InputMethodHandler.prototype = {
  QueryInterface: ChromeUtils.generateQI([Ci.nsIObserver,
                                          Ci.nsISupportsWeakReference,
                                          Ci.nsISelectionListener]),

  // Weak-ref used to keep track of the currently focused element.
  _currentFocusedElement: null,

  _init: function() {
    Logger.debug("JSScript: InputMethodHandler.js loaded");
    addEventListener("focus", this, true);
    addEventListener("blur", this, true);
    addEventListener("input", this, false);
  },

  get focusedElement() {
    return this._currentFocusedElement && this._currentFocusedElement.get();
  },

  notifySelectionChanged: function(doc, sel, reason) {
    this._sendInputContext(this.focusedElement);
  },

  handleEvent: function(aEvent) {
    switch (aEvent.type) {
      case "focus": {
        let currentElement = aEvent.target;
        if (this._isTextInput(currentElement)) {
          this._sendInputAttributes(currentElement);
          try {
            this._currentFocusedElement = Cu.getWeakReference(currentElement);
            if (this._isInputContextAvailable(currentElement)) {
              let selection = currentElement.editor.selectionController
                              .getSelection(Ci.nsISelectionController.SELECTION_NORMAL);
              selection.addSelectionListener(this);
            }
          } catch (e) {
            Logger.warn("InputMethodHandler: adding selection listener failed", e);
          }
        }
        break;
      }

      case "blur": {
        let focused = this.focusedElement;
        if (focused) {
          if (this._isInputContextAvailable(focused)) {
            try {
              let selection = focused.editor.selectionController
                              .getSelection(Ci.nsISelectionController.SELECTION_NORMAL);
              selection.removeSelectionListener(this);
              this._resetInputContext(focused);
            } catch (e) {
              Logger.warn("InputMethodHandler: removing selection listener failed", e);
            }
          }
          this._resetInputAttributes(focused);
        }
        this._currentFocusedElement = null;
        break;
      }

      case "input": {
        let currentElement = aEvent.target;
        if (currentElement !== this.focusedElement) {
          break;
        }
        this._sendInputContext(currentElement);
        break;
      }
    }
  },

  _sendInputContext: function(aElement) {
    if (!this._isInputContextAvailable(aElement) || aElement !== this.focusedElement) {
      return;
    }

    try {
      let winId = Services.embedlite.getIDByWindow(aElement.ownerGlobal);
      Services.embedlite.sendAsyncMessage(winId, "InputMethodHandler:SetInputContext",
                                          JSON.stringify({surroundingText: aElement.value,
                                                          cursorPosition: aElement.selectionStart,
                                                          anchorPosition: aElement.selectionEnd}));
    } catch (e) {
      Logger.warn("InputMethodHandler: sending async message failed", e);
    }
  },

  _resetInputContext: function(aElement) {
    try {
      let winId = Services.embedlite.getIDByWindow(aElement.ownerGlobal);
      Services.embedlite.sendAsyncMessage(winId, "InputMethodHandler:ResetInputContext", "[]");
    } catch (e) {
      Logger.warn("InputMethodHandler: sending async message failed", e);
    }
  },

  _sendInputAttributes: function(aElement) {
    try {
      let winId = Services.embedlite.getIDByWindow(aElement.ownerGlobal);
      Services.embedlite.sendAsyncMessage(winId, "InputMethodHandler:SetInputAttributes",
                                          JSON.stringify({autocomplete: aElement.getAttribute("autocomplete"),
                                                          autocapitalize: aElement.getAttribute("autocapitalize")}));
    } catch (e) {
      Logger.warn("InputMethodHandler: sending async message failed", e);
    }
  },

  _resetInputAttributes: function(aElement) {
    try {
      let winId = Services.embedlite.getIDByWindow(aElement.ownerGlobal);
      Services.embedlite.sendAsyncMessage(winId, "InputMethodHandler:ResetInputAttributes", "[]");
    } catch (e) {
      Logger.warn("InputMethodHandler: sending async message failed", e);
    }
  },

  _isTextInput: function(aElement) {
    return (Util.isEditable(aElement) && aElement.editor) &&
           !aElement.readOnly &&
           !this._isDisabledElement(aElement);
  },

  _isInputContextAvailable: function(aElement) {
    return this._isTextInput(aElement) &&
           (aElement.type !== "password");
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

function InputMethodHandler() {
  this._init();
}

gInputMethodHandler = new InputMethodHandler();
