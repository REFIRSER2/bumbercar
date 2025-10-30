fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'BumberCar Team'
description 'FiveM Bumper Car Game Mode'
version '1.0.0'

-- Shared scripts
shared_scripts {
    'shared/constants.lua',
    'shared/utils.lua'
}

-- Config files
shared_scripts {
    'config/config.lua',
    'config/vehicles.lua',
    'config/items.lua',
    'config/maps.lua',
    'config/weapons.lua'
}

-- Client scripts
client_scripts {
    'client/spawn.lua',     -- 스폰 관리 (먼저 로드)
    'client/main.lua',
    'client/ui.lua',
    'client/lobby.lua',
    'client/round.lua',
    'client/vehicle.lua',
    'client/damage.lua',
    'client/items.lua',
    'client/boundary.lua',
    'client/spectator.lua'
}

-- Server scripts
server_scripts {
    'server/main.lua',
    'server/lobby.lua',
    'server/round.lua',
    'server/damage.lua',
    'server/items.lua',
    'server/teams.lua'
}

-- NUI
ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/*.css',
    'html/js/*.js',
    'html/assets/**/*'
}
