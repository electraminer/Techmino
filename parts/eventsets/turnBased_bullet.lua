local turnBased = require "parts.eventsets.turnBased"
return turnBased.withTimeControls({
    mainTime = 0,
    turnTime = 0,
    periodTime = 60 * 5,
    increment = true,
    periods = 5,
    autoCommit = true,
})