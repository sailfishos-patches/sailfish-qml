.import Sailfish.Weather 1.0 as Weather
.pragma library

var user = ""
var password = ""
var token = ""
var tokenRequest
var pendingTokenRequests = []
var lastUpdate = new Date()

function fetchToken(model) {
    if (model == undefined) {
        console.warn("Token requested for undefined or null model")
        return false
    }

    if (token.length > 0 && !updateAllowed()) {
        model.token = token
        return true
    } else {
        if (!tokenRequest) {

            if (user.length === 0 || password.length === 0) {
                var keyProvider = Qt.createQmlObject(
                            "import com.jolla.settings.accounts 1.0; StoredKeyProvider {}",
                            model, "StoreKeyProvider")

                user = keyProvider.storedKey("foreca", "", "user")
                password = keyProvider.storedKey("foreca", "", "password")
                keyProvider.destroy()

                if (user.length === 0 || password.length === 0) {
                    console.warn("Unable to get Foreca credentials needed to identify with the service")
                    return false
                }
            }

            tokenRequest = new XMLHttpRequest()

            var url = "https://pfa.foreca.com/authorize/token?user=" + user + "&password=" + password

            // Send the proper header information along with the tokenRequest
            tokenRequest.onreadystatechange = function() { // Call a function when the state changes.
                if (tokenRequest.readyState == XMLHttpRequest.DONE) {
                    if (tokenRequest.status == 200) {
                        var json = JSON.parse(tokenRequest.responseText)
                        token = json["access_token"]
                    } else {
                        token = ""
                        console.log("Failed to obtain Foreca token. HTTP error code: " + tokenRequest.status)
                    }

                    for (var i = 0; i < pendingTokenRequests.length; i++) {
                        pendingTokenRequests[i].token = token
                        if (tokenRequest.status !== 200) {
                            pendingTokenRequests[i].status = (tokenRequest.status === 401) ? Weather.Weather.Unauthorized : Weather.Weather.Error
                        }
                    }
                    pendingTokenRequests = []
                    tokenRequest = undefined
                }
            }
            tokenRequest.open("GET", url)
            tokenRequest.send()
        }
        pendingTokenRequests[pendingTokenRequests.length] = model
    }
    return false
}

function updateAllowed(interval) {
    // only update token if older than 45 minutes
    interval = interval === undefined ? 45*60*1000 : interval
    var now = new Date()
    var updateAllowed = now.getDate() != lastUpdate.getDate() || (now - interval > lastUpdate)
    if (updateAllowed) {
        lastUpdate = now
    }
    return updateAllowed
}
