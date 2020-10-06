
WorkerScript.onMessage = function(msg) {
    var i
    var model = msg.model

    if (msg.action === "insert") {
        model.insert(0, {
                         "pagenr": msg.pagenr,
                         "text": msg.text,
                         "color": msg.color
                     })
        for (i = 1; i < model.count; i++) {
            model.setProperty(i, "pagenr", model.get(i).pagenr + 1)
        }

    } else if (msg.action === "remove") {
        model.remove(msg.idx)
        for (var i = msg.idx; i < model.count; i++) {
            model.setProperty(i, "pagenr", model.get(i).pagenr - 1)
        }

    } else if (msg.action === "colorupdate") {
        model.setProperty(msg.idx, "color", msg.color)

    } else if (msg.action === "textupdate") {
        model.setProperty(msg.idx, "text", msg.text)

    } else if (msg.action === "movetotop") {
        model.move(msg.idx, 0, 1) // move 1 item to position 0
        model.setProperty(0, "pagenr", 1)
        for (i = 1; i <= msg.idx; i++) {
            model.setProperty(i, "pagenr", model.get(i).pagenr + 1)
        }

    } else if (msg.action === "update") {
        var results = msg.results
        if (model.count > results.length) {
            model.remove(results.length, model.count - results.length)
        }
        for (i = 0; i < results.length; i++) {
            var result = results[i]
            if (i < model.count) {
                model.set(i, {
                              "pagenr": result.pagenr,
                              "text": result.text,
                              "color": result.color
                          })
            } else {
                model.append({
                                 "pagenr": result.pagenr,
                                 "text": result.text,
                                 "color": result.color
                             })
            }
        }
    }

    model.sync()
    WorkerScript.sendMessage({"reply": msg.action})
}
