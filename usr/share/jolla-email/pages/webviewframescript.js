/*
 * Copyright (c) 2020 Open Mobile Platform LLC.
 *
 * License: Proprietary
 */

Services.scriptloader.loadSubScript("chrome://embedlite/content/ClickEventBlocker.js", this);

addEventListener("DOMContentLoaded", function () {
    // If the document doesn't have a viewport meta tag assume it is going to scale poorly and
    // add one so it doesn't.
    var viewport = content.document.querySelector("meta[name=viewport]");
    if (!viewport) {
        viewport = content.document.createElement("meta");
        viewport.name = "viewport"
        viewport.content = "width=device-width, initial-scale=1"
        content.document.head.appendChild(viewport);
    }

    if (content.document.images.length > 0) {
        sendAsyncMessage("JollaEmail:DocumentHasImages", {})
    }
})

let global = this

// This will send "embed:OpenLink" message when a link is clicked.
ClickEventBlocker.init(global)
