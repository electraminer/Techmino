local turnBased = require "parts.eventsets.turnBased"
return turnBased.withTimeControls({
    mainTime = 1e99,
    turnTime = 1e99,
    periodTime = 1e99,
    increment = false,
    periods = 5,
    autoCommit = false,
})