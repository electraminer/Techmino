local turnBased = require "parts.eventsets.turnBased"
return turnBased.withTimeControls({
    mainTime = 60 * 60 * 60,
    turnTime = 60 * 60,
    periodTime = 60 * 60,
    increment = false,
    periods = 5,
    autoCommit = false,
})