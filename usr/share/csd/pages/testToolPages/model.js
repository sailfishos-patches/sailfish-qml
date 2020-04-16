var grid = [];

function initializeGridData(entries) {
    for (var i = 0; i < entries; ++i)
        grid[i] = false
}

function allPass(index) {
    if (grid[index])
        return false

    grid[index] = true

    for (var i = 0; i < grid.length; ++i) {
        if (!grid[i])
            return false
    }

    return true
}
