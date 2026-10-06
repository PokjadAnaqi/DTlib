DTConfig = DTConfig or {}

DTConfig.Debug = false
DTConfig.Strict = false

DTConfig.Adapters = {
    framework = 'auto',
    inventory = 'auto',
    target = 'auto',
    database = 'auto',
    weather = 'auto',
    ui = 'auto',
    notify = 'auto',
    textui = 'auto',
    progress = 'auto',
    input = 'auto',
    menu = 'auto',
    listmenu = 'auto',
    alert = 'auto'
}

DTConfig.Console = {
    enabled = true,
    startupSummary = true,
    resourceEvents = true,
    timestamps = true,
    audit = true
}

DTConfig.UI = {
    notifyDuration = 4500,
    notifyMaxVisible = 5,
    notifyPosition = 'top-right',
    notifySize = 'md',
    resolveItemLabels = true,
    textUIPosition = 'right-center',
    progressPosition = 'bottom-center',
    menuPosition = 'offcenter-right'
}


DTConfig.Placement = {
    distanceLimit = 8.0,
    showHelp = true,
    outline = true,
    freezeAfter = true,
    -- Player PED is frozen automatically while placement controls are active.
    -- Individual calls can opt out with freezePlayer = false.
    freezePlayer = true,

    -- Default placement engine: DTlib native direct DrawGizmo profile from v1.0.6.
    -- This is intentionally the default even when object_gizmo is running because
    -- it gives the proven direct X/Y/Z drag feel requested for the DT ecosystem.
    -- object_gizmo v3 remains available as an optional provider.
    provider = 'native',
    objectGizmoMajor = 3,

    -- Native camera uses the v1.0.6 direct prop gizmo plus object-orbit drag.
    -- LMB on a gizmo handle stays 1:1; LMB drag outside an active handle orbits the prop.
    nativeOrbit = {
        minRadius = 1.5,
        maxRadius = 25.0,
        zoomStep = 0.75,
        sensitivity = 0.005,
        blend = 250,
        dragThresholdPx = 4.0
    },

    -- Official object_gizmo v3.0.0 interaction defaults used by the adapter.
    objectGizmo = {
        camera = 'orbit',
        mode = 'translate',
        space = 'world',
        pivot = 'center',
        gizmoSize = 0.5,
        translationSnap = 0.25,
        rotationSnap = 15.0,
        scaleSnap = 0.1,
        snap = false,
        orbit = {
            minRadius = 1.5,
            maxRadius = 25.0,
            zoomStep = 0.75,
            sensitivity = 0.005,
            blend = 250
        }
    }
}

-- DT Waypoint can be disabled completely without removing the module files.
-- Configure waypoint behaviour here; DTlib no longer uses dtlib_* convars.
DTConfig.Waypoint = {
    enabled = true,
    syncMapWaypoint = true,

    defaults = {
        type = 'objective',
        label = 'OBJECTIVE',
        subtitle = 'DT NAVIGATION',
        color = '#9db34f',
        icon = 'fa-solid fa-location-dot',
        size = 1.0,
        drawDistance = 500.0,
        fadeDistance = 420.0,
        displayDistance = true,
        heightOffset = 1.15,
        minScale = 0.72,
        maxScale = 14.0
    },

    mapWaypoint = {
        type = 'objective',
        label = 'NAV POINT',
        subtitle = 'PLAYER WAYPOINT',
        color = '#72a6c9',
        icon = 'fa-solid fa-location-arrow',
        size = 0.9,
        drawDistance = 1000.0,
        fadeDistance = 850.0,
        displayDistance = true,
        pulse = true,
        updateInterval = 500,
        moveThreshold = 2.0
    },

    dui = {
        width = 512,
        height = 1024,
        readyTimeout = 5000
    },

    -- Native marker is only used if the DUI page cannot become ready.
    fallback = {
        enabled = true,
        markerType = 28,
        r = 157,
        g = 179,
        b = 79,
        a = 190
    },

    rendering = {
        -- sprite = reliable screen-space DUI anchored to world coords (recommended)
        -- world  = legacy DrawTexturedPoly billboard
        mode = 'sprite',
        updateInterval = 150,
        distanceUpdateInterval = 250,
        perspectiveDivisor = 22.0,
        baseWidth = 1.18,
        baseHeight = 1.78,
        spriteWidth = 0.155,
        spriteMinFactor = 0.86,
        spriteMaxFactor = 1.08,
        maxVisible = 18
    }
}

DTConfig.Minigames = {
    -- Master switch for DTlib minigame adapters. Lation UI and ox_lib remain optional.
    enabled = true,
    -- auto | lation_ui | ox_lib | disabled
    provider = 'auto'
}

DTConfig.Security = {
    defaultWindowMs = 10000,
    defaultMaxCalls = 10,
    adminAce = 'admin',
    godAce = 'god'
}

DTConfig.Discord = {
    tokenConvar = 'dt_eco_discord_bot_token',
    guildIdConvar = 'dt_eco_discord_guild_id',
    cacheSeconds = 60
}

-- DTlib's local provider registry. External resources are optional backends.
-- Each module selects exactly one started backend. Restart DTlib after changing it.
DTConfig.Ecosystem = {
    enabled = true,
    locale = 'en',
    providers = {
        framework = 'auto', inventory = 'auto', target = 'auto',
        notify = 'auto', helptext = 'auto', progressbar = 'auto',
        input = 'auto', menu = 'auto', weather = 'auto',
        fuel = 'auto', vehiclekey = 'auto', banking = 'auto',
        phone = 'auto', doorlock = 'auto', dispatch = 'auto',
        clothing = 'auto', housing = 'auto', shops = 'native',
        skills = 'native', bossmenu = 'auto', zones = 'auto', dialogue = 'native'
    }
}

-- Awaited cross-resource callbacks fail cleanly if the other side never replies.
DTConfig.CallbackTimeout = 30000
