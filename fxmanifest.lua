fx_version   'cerulean'
use_experimental_fxv2_oal 'yes'
lua54 'yes'
game 'gta5'

description 'Printers'
author 'xT Development'

shared_scripts { '@ox_lib/init.lua', '@Renewed-Lib/init.lua' }

client_scripts {
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}

files {
    'configs/*.lua',
    'modules/**/*.lua'
}