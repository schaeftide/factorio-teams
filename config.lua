return {
    --[[
    defines all needed forces - every component is based on this configuration.

    should have following syntax:

    normal force name = {
        name = "lowerCaseForceName", -- just an identifier, I don't know if I still use it
        title = "Force Title", -- is used for every kind of buttons, messages etc
        cName = 'normal force name', -- this name is used as game.force.['normal force name'
        color = { r = 0, g = 0.56 , b = 1 , a = 0.8 } -- Color of force
    }
    ]] --
    forcesData = {
    },
    points = {
        startingAreaRadius = 50, -- in this radius every tree will be destroyed
        start = {
            -- defines start point of map
            x = math.random(220, 1060),
            y = math.random(220, 1060)
        }, -- defines distance between spawn points for teams
        distance = {
            min = 1200,
            max = 1800,
        },
        numberOfTrysBeforeError = 40 -- this is just a helper value (if we try to locate a non colliding point, we try it max XX times before we abort)
    },
    -- defines distance
    d = 60 * 3, -- in this area all enemy will be destroyesd
    -- defines big distance
    bd = 40 * 3 * 3, -- this area will be charted for every force (should be bigger then d)
    -- should every player be notified if another force started or finished a research
    researchMessage = {
        enabled = true
    },
    -- should every player be notified if another force is attacked (destroy one building)
    attackMessage = {
        enabled = true,
        interval = 5*MINUTES
    },
    enableTeams = {
        after = 30 * SECONDS, -- teams are eneabled after XX Seconds
        messageInterval = 10 * SECONDS -- message interval /(when are the teams unlocked)
    },
    teamMessageGui = {
        enabled = true
    },
    allianceGui = {
        enabled = true,
        changeAbleTick = 5 * MINUTES -- alliances could only be changed every XXX ticks
    }
}