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

  init: function init(context, params) {
    this._context = context;
    this._allowNavigationInSameOrigin = params && params.allowNavigationInSameOrigin;
    Services.els.addSystemEventListener(context, "click", this, true);
  },

  handleEvent(event) {
    switch (event.type) {
    case "click":
      let originalTarget = event.originalTarget;
      let ownerDoc = originalTarget.ownerDocument;
      if (!ownerDoc) {
        return;
      }

      let [href, isSameOrigin] = this._hrefForClickEvent(event);

      if (this._allowNavigationInSameOrigin && isSameOrigin) {
        // Do not block clicks to the same origin links
        return;
      }
      event.preventDefault();
      if (href) {
        sendAsyncMessage("embed:OpenLink", {
                          "uri":  href
                        })
      }
    }
  },

  /**
   * Extracts href for the current click target and checks if it has same
   * origin as current page.
   *
   * @param event
   *        The click event.
   * @return [href, isSameOrigin].
   */
  _hrefForClickEvent(event) {
    function isHTMLLink(aNode) {
      // Be consistent with what nsContextMenu.js does.
      return ((aNode instanceof content.HTMLAnchorElement && aNode.href) ||
              (aNode instanceof content.HTMLAreaElement && aNode.href) ||
              aNode instanceof content.HTMLLinkElement);
    }

    let self = this;
    function isSameOriginHref(referrerURI, href) {
      if (!self._allowNavigationInSameOrigin)
        return null;
      const securityManager = Services.scriptSecurityManager;
      try {
        var targetURI = makeURI(href);
        securityManager.checkSameOriginURI(referrerURI, targetURI, false);
        return true;
      } catch (e) { }
      return false;
    }

    let node = event.target;
    while (node && !isHTMLLink(node)) {
      node = node.parentNode;
    }

    if (node)
      return [node.href, isSameOriginHref(node.ownerDocument.baseURIObject, node.href)];

    // linkNode will be null if the click wasn't on an anchor element like
    // SVG links (XLink). If there is no linkNode, try simple XLink.
    let href, baseURI;
    node = event.target;
    while (node && !href) {
      if (node.nodeType == content.Node.ELEMENT_NODE &&
          (node.localName == "a" ||
           node.namespaceURI == "http://www.w3.org/1998/Math/MathML")) {
        href = node.getAttribute("href") ||
               node.getAttributeNS("http://www.w3.org/1999/xlink", "href");
        if (href) {
          baseURI = node.ownerDocument.baseURIObject;
          break;
        }
      }
      node = node.parentNode;
    }

    if (href) {
      let document = node.ownerDocument;
      let link = document.createElement('a');
      link.href = href;
      let uri = Services.io.newURI(href, null, baseURI).spec;

      return [uri, isSameOriginHref(baseURI, uri)];
    }
    return [null, null];
  }
};
