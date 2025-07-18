fx_version 'cerulean'
use_experimental_fxv2_oal 'yes'
lua54 'yes'
game 'gta5'
name 'ox_inventory'
author 'Overextended'
version '2.46.0'
repository 'https://github.com/JericoFX/ox_inventory'
description 'Slot-based inventory with item metadata support'

dependencies {
    '/server:6116',
    '/onesync',
    'oxmysql',
    'ox_lib',
}

shared_script { '@ox_lib/init.lua', "modules/config/config_shared.lua" }


ox_libs {
    'locale',
    'table',
    'math',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    "modules/config/config_server.lua",
    'init.lua'
}

client_script { "modules/config/config_client.lua", 'init.lua' }

ui_page 'web/build/index.html'

files {

    'client.lua',
    'server.lua',
    'locales/*.json',
    'web/build/index.html',
    'web/build/assets/*.js',
    'web/build/assets/*.css',
    'web/images/*.png',
    'modules/**/shared.lua',
    'modules/**/client.lua',
    'modules/**/**/client.lua',
    'modules/bridge/**/client.lua',
    'modules/inventory/inventory_types_client.lua',
    'data/*.lua',
}
