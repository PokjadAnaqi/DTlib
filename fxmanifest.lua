fx_version 'cerulean'
game 'gta5'

name 'DTlib'
author 'DT Ecosystem'
description 'Independent modular runtime library for DT ecosystem resources'
version '1.3.0-beta.1'

ui_page 'html/index.html'

files {
    'init.lua',
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/waypoint.html',
    'html/waypoint.css',
    'html/waypoint.js'
}

shared_scripts {
    'settings/sharedConfig.lua',
    'shared/utils.lua',
    'shared/core.lua',
    'lib/modules/shared.lua',
    'modules/framework/shared.lua',
    'modules/notify/shared.lua',
    'modules/ecosystem/catalog.lua'
}

client_scripts {
    'settings/clientConfig.lua',

    'lib/fivem/client.lua',
    'lib/callback/client.lua',

    'modules/ecosystem/runtime.lua',

    'modules/framework/*/client.lua',
    'modules/framework/client.lua',

    'modules/inventory/*/client.lua',
    'modules/ecosystem/inventory_client.lua',
    'modules/inventory/client.lua',

    'modules/target/*/client.lua',
    'modules/target/client.lua',

    'modules/notify/*/client.lua',
    'modules/notify/client.lua',

    'modules/progressbar/*/client.lua',
    'modules/progressbar/client.lua',

    'modules/helptext/*/client.lua',
    'modules/helptext/client.lua',

    'modules/menu/*/client.lua',
    'modules/menu/client.lua',

    'modules/input/*/client.lua',
    'modules/input/client.lua',

    'modules/alert/*/client.lua',
    'modules/alert/client.lua',

    'modules/ecosystem/adapters_client.lua',
    'modules/listmenu/client.lua',

    'modules/weather/*/client.lua',
    'modules/weather/client.lua',

    'modules/ui_suspend/client.lua',
    'modules/placement/dtlib/gizmo.js',
    'modules/placement/dtlib/client.lua',
    'modules/waypoint/dtlib/client.lua',
    'modules/minigames/*/client.lua',
    'modules/minigames/client.lua',
    'modules/zones/client.lua',
    'lib/vehicle/client.lua',

    'modules/ecosystem/ui_bridge_client.lua',
    'modules/providers/*_shared.lua',
    'modules/providers/*_client.lua',
    'modules/bootstrap/client.lua'
}

server_scripts {
    'settings/serverConfig.lua',

    'lib/logger/server.lua',
    'lib/callback/server.lua',
    'lib/fivem/server.lua',

    'modules/ecosystem/runtime.lua',

    'modules/framework/*/server.lua',
    'modules/framework/server.lua',

    'modules/inventory/*/server.lua',
    'modules/ecosystem/inventory_server.lua',
    'modules/inventory/server.lua',

    'modules/database/*/server.lua',
    'modules/database/server.lua',

    'modules/weather/*/server.lua',
    'modules/weather/server.lua',

    'modules/notify/server.lua',

    'lib/security/server.lua',
    'lib/discord/server.lua',
    'modules/waypoint/dtlib/server.lua',

    'modules/providers/*_shared.lua',
    'modules/providers/*_server.lua',
    'modules/bootstrap/server.lua'
}
