fx_version 'cerulean'
use_experimental_fxv2_oal 'yes'
lua54 'yes'
game 'gta5'
name 'ox_inventory'
author 'Overextended'
version '2.44.1'
repository 'https://github.com/overextended/ox_inventory'
description 'Slot-based inventory with item metadata support'

dependencies {
    '/server:6116',
    '/onesync',
    'oxmysql',
    'ox_lib',
    'ox_target',
}

shared_script '@ox_lib/init.lua'

ox_libs {
    'locale',
    'table',
    'math',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'init.lua'
}

client_script 'init.lua'

ui_page 'build/index.html'

files {
    'client.lua',
    'server.lua',

    'locales/*.json',

    'build/index.html',
    'build/assets/*.js',
    'build/assets/*.css',

    'modules/**/shared.lua',
    'modules/**/client.lua',
    'modules/bridge/**/client.lua',

    'data/*.lua',
    'data/**/*.lua',
}
