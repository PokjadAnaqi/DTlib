fx_version 'cerulean'
game 'gta5'

name 'DTlib'
author 'DT Ecosystem'
description 'Independent modular runtime library for DT ecosystem resources'
version '1.4.0-beta.1'

ui_page 'html/dist/index.html'

files {
    'init.lua',
    'modules/**',
    'lib/**',
    'locales/*.json',
    'html/**'
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
    'lib/admin/client.lua',

    'modules/ecosystem/runtime.lua',

    'modules/framework/es_extended/dt_client.lua',
    'modules/framework/ox_core/client.lua',
    'modules/framework/qb-core/dt_client.lua',
    'modules/framework/qbx_core/dt_client.lua',
    'modules/framework/standalone/client.lua',
    'modules/framework/client.lua',

    'modules/inventory/framework/client.lua',
    'modules/inventory/ox_inventory/dt_client.lua',
    'modules/inventory/qb-inventory/dt_client.lua',
    'modules/ecosystem/inventory_client.lua',
    'modules/inventory/client.lua',
    'modules/inventory/catalog.lua',

    'modules/target/none/client.lua',
    'modules/target/ox_target/dt_client.lua',
    'modules/target/qb-target/dt_client.lua',
    'modules/target/sleepless_interact/dt_client.lua',
    'modules/target/interact/client.lua',
    'modules/target/client.lua',

    'modules/notify/lation_ui/dt_client.lua',
    'modules/notify/native/client.lua',
    'modules/notify/okokNotify/dt_client.lua',
    'modules/notify/ox_lib/dt_client.lua',
    'modules/notify/client.lua',

    'modules/progressbar/lation_ui/dt_client.lua',
    'modules/progressbar/native/client.lua',
    'modules/progressbar/ox_lib/dt_client.lua',
    'modules/progressbar/client.lua',

    'modules/helptext/lation_ui/dt_client.lua',
    'modules/helptext/native/client.lua',
    'modules/helptext/okokTextUI/dt_client.lua',
    'modules/helptext/ox_lib/dt_client.lua',
    'modules/helptext/client.lua',

    'modules/menu/lation_ui/dt_client.lua',
    'modules/menu/native/client.lua',
    'modules/menu/ox_lib/dt_client.lua',
    'modules/menu/client.lua',

    'modules/input/lation_ui/dt_client.lua',
    'modules/input/native/client.lua',
    'modules/input/ox_lib/dt_client.lua',
    'modules/input/client.lua',

    'modules/alert/lation_ui/client.lua',
    'modules/alert/native/client.lua',
    'modules/alert/ox_lib/client.lua',
    'modules/alert/client.lua',

    'modules/ecosystem/adapters_client.lua',
    'modules/listmenu/client.lua',

    'modules/weather/native/client.lua',
    'modules/weather/qb-weathersync/client.lua',
    'modules/weather/renewed-weathersync/client.lua',
    'modules/weather/cd_easytime/client.lua',
    'modules/weather/client.lua',

    'modules/ui_suspend/client.lua',
    'modules/placement/dtlib/gizmo.js',
    'modules/placement/dtlib/client.lua',
    'modules/waypoint/dtlib/client.lua',
    'modules/minigames/lation_ui/client.lua',
    'modules/minigames/ox_lib/client.lua',
    'modules/minigames/client.lua',
    'modules/zones/client.lua',
    'lib/vehicle/client.lua',

    'modules/ecosystem/ui_bridge_client.lua',
    'modules/providers/clothing_shared.lua',
    'modules/providers/dispatch_shared.lua',
    'modules/providers/framework_shared.lua',
    'modules/providers/inventory_shared.lua',
    'modules/providers/services_shared.lua',
    'modules/providers/shops_shared.lua',
    'modules/providers/skills_shared.lua',
    'modules/providers/ui_shared.lua',
    'modules/providers/utilities_shared.lua',
    'modules/providers/ui_client.lua',
    'modules/providers/vehicle_client.lua',
    'modules/providers/world_client.lua',
    'modules/bootstrap/client.lua'
}

server_scripts {
    'settings/serverConfig.lua',

    'lib/logger/server.lua',
    'lib/callback/server.lua',
    'lib/fivem/server.lua',

    'modules/ecosystem/runtime.lua',

    'modules/framework/es_extended/dt_server.lua',
    'modules/framework/ox_core/server.lua',
    'modules/framework/qb-core/dt_server.lua',
    'modules/framework/qbx_core/dt_server.lua',
    'modules/framework/standalone/server.lua',
    'modules/framework/server.lua',

    'modules/inventory/framework/server.lua',
    'modules/inventory/ox_inventory/dt_server.lua',
    'modules/inventory/qb-inventory/dt_server.lua',
    'modules/ecosystem/inventory_server.lua',
    'modules/inventory/server.lua',
    'modules/inventory/catalog.lua',

    'modules/database/ghmattimysql/server.lua',
    'modules/database/none/server.lua',
    'modules/database/oxmysql/server.lua',
    'modules/database/server.lua',

    'modules/weather/native/server.lua',
    'modules/weather/qb-weathersync/server.lua',
    'modules/weather/renewed-weathersync/server.lua',
    'modules/weather/cd_easytime/server.lua',
    'modules/weather/server.lua',

    'modules/notify/server.lua',

    'lib/security/server.lua',
    'lib/admin/server.lua',
    'lib/discord/server.lua',
    'modules/waypoint/dtlib/server.lua',

    'modules/providers/clothing_shared.lua',
    'modules/providers/dispatch_shared.lua',
    'modules/providers/framework_shared.lua',
    'modules/providers/inventory_shared.lua',
    'modules/providers/services_shared.lua',
    'modules/providers/shops_shared.lua',
    'modules/providers/skills_shared.lua',
    'modules/providers/ui_shared.lua',
    'modules/providers/utilities_shared.lua',
    'modules/providers/banking_server.lua',
    'modules/providers/inventory_server.lua',
    'modules/version/server/update.lua',
    'modules/bootstrap/server.lua'
}
