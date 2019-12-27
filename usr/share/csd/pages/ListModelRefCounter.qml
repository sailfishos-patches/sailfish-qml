/*
 * Copyright (c) 2016 - 2019 Jolla Ltd.
 *
 * License: Proprietary
 */

import QtQml 2.2
pragma Singleton

QtObject {
    property var _models: []

    function addModel(model) {
        _models.push(model)
    }

    function releaseModel(model) {
        var index = _models.indexOf(model);
        if (index != -1) {
            _models.splice(index, 1);
        }
    }

    function modelIndexForUrl(url) {
        var list = []
        for (var i = 0; i < _models.length; ++i) {
            var model = _models[i]
            var index = indexForUrl(model, url)
            if (index >= 0) {
                list.push({"model": model, "index": index})
            }
        }
        return list
    }

    function indexForUrl(model, url) {
        if (!model) {
            return -1
        }

        for (var i = 0; i < model.count; ++i) {
            if (model.get(i).url == url) {
                return i
            }
        }
        return -1
    }
}
