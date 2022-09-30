/*
 * Copyright (c) 2020 Open Mobile Platform LLC.
 */

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

Components.utils.import("resource://gre/modules/Services.jsm");
let makeURI = Components.utils.import("resource://gre/modules/BrowserUtils.jsm", {}).BrowserUtils.makeURI;

var ClickEventBlocker = {
  _context: null,
  _allowNavigationInSameOrigin: false,
  _rootOrigin: null,

  init: function init(context, params) {
    this._context = context;
    this._allowNavigationInSameOrigin = params && params.allowNavigationInSameOrigin;
    Services.els.addSystemEventListener(context, "click", this, true);
    this._rootOrigin = null;
  },

  handleEvent(event) {
    switch (event.type) {
    case "click":
      let originalTarget = event.originalTarget;
      let ownerDoc = originalTarget.ownerDocument;
      if (!ownerDoc) {
        return;
      }

      let [referrerURI, href, isForm] = this._hrefForClickEvent(event);
      if (!this._rootOrigin) {
        // Keep track of the original origin to compare future clicks against
        this._rootOrigin = referrerURI;
      }
      let isSameOrigin = this._isSameOriginHref(this._rootOrigin, href);

      // If it's a click in the same origin, or a form, handle it inside
      // the captive portal
      if (this._allowNavigationInSameOrigin && (isSameOrigin || isForm)) {
        // Do not block clicks to the same origin links or form actions
        return;
      }
      if (href) {
        event.preventDefault();
        sendAsyncMessage("embed:OpenLink", {
                          "uri":  href
                        })
      }
    }
  },

  /**
   * Checks of two URLs (usually a referer and a link href)
   * have the same origin.
   *
   * @param referrerURI
   *        The referrer URI.
   * @param href
   *        The href URI to compare with the referrer URI.
   * @return isSameOrigin
   */
  _isSameOriginHref(referrerURI, href) {
    if (!this._allowNavigationInSameOrigin)
      return null;
    const securityManager = Services.scriptSecurityManager;
    try {
      var targetURI = makeURI(href);
      securityManager.checkSameOriginURI(referrerURI, targetURI, false);
      return true;
    } catch (e) { }
    return false;
  },

  /**
   * Extracts referrer URI and href for the current click target.
   * When the click relates to a form (POST or GET) then isFrom
   * will be returned as true.
   *
   * @param event
   *        The click event.
   * @return [referrerURI, href, isForm].
   */
  _hrefForClickEvent(event) {
    function isHTMLLink(aNode) {
      // Be consistent with what nsContextMenu.js does.
      return ((aNode instanceof content.HTMLAnchorElement && aNode.href) ||
              (aNode instanceof content.HTMLAreaElement && aNode.href) ||
              aNode instanceof content.HTMLLinkElement);
    }

    let node = event.target;
    while (node && !isHTMLLink(node)) {
      node = node.parentNode;
    }

    if (node) {
      return [node.ownerDocument.baseURIObject, node.href, false];
    }

    // linkNode will be null if the click wasn't on an anchor element like
    // SVG links (XLink). If there is no linkNode, try simple XLink.
    let href, baseURI
    let isForm = false;
    node = event.target;
    while (node && !href) {
      if (node.nodeType == content.Node.ELEMENT_NODE) {
        if ((node.localName == "a" ||
             node.namespaceURI == "http://www.w3.org/1998/Math/MathML")) {
          href = node.getAttribute("href") ||
                 node.getAttributeNS("http://www.w3.org/1999/xlink", "href");
        } else if (node.localName == "form") {
          href = node.getAttribute("action");
          isForm = true;
        }
      }
      if (href) {
        baseURI = node.ownerDocument.baseURIObject;
        break;
      }
      node = node.parentNode;
    }

    if (href) {
      let document = node.ownerDocument;
      let link = document.createElement('a');
      link.href = href;
      let uri = Services.io.newURI(href, null, baseURI).spec;

      return [baseURI, uri, isForm];
    }
    return [null, null, false];
  }
};
