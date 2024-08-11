local turnBased = require "parts.eventsets.turnBased"
return turnBased.withTimeControls({
    mainTime = 60 * 60 * 3,
    turnTime = 60 * 5,
    periodTime = 60 * 10,
    increment = true,
    periods = 5,
    autoCommit = true,
})