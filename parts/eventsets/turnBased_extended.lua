local turnBased = require "parts.eventsets.turnBased"
return turnBased.withTimeControls({
    mainTime = 60 * 60 * 30,
    turnTime = 60 * 30,
    periodTime = 60 * 30,
    increment = false,
    periods = 5,
    autoCommit = false,
})