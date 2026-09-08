-- Ride - one command to mount/dismount

addon.name    = 'Ride'
addon.author  = 'Seekey'
addon.version = '1.0'
addon.desc    = 'Toggle your mount with /ride'
addon.link    = 'https://github.com/seekey13/Ride'

require('common')
local chat = require('chat')
local settings = require('settings')

local MOUNTED_BUFF = 252
local COOLDOWN = 60

local config = settings.load(T{ mount = 'Raptor' })
settings.register('settings', 'settings_update', function (s)
    if s ~= nil then config = s end
end)

local last_mount = 0  -- os.time() of the last /mount we issued

-- ponytail: buff array is fixed at 32 slots; 255/0 are empty markers
local function is_mounted()
    local player = AshitaCore:GetMemoryManager():GetPlayer()
    if player == nil then return false end
    local BUFFS = player:GetBuffs()
    if BUFFS == nil then return false end
    for i = 1, 32 do
        if BUFFS[i] == MOUNTED_BUFF then return true end
    end
    return false
end

ashita.events.register('command', 'command_cb', function (e)
    local args = e.command:args()
    if #args == 0 or args[1]:lower() ~= '/ride' then return end
    e.blocked = true

    if #args > 1 then
        config.mount = table.concat(args, ' ', 2)
        settings.save()
        print(chat.header(addon.name):append(chat.message('Mount set to ' .. config.mount)))
        return
    end

    if is_mounted() then
        AshitaCore:GetChatManager():QueueCommand(1, '/dismount')
        return
    end

    -- ponytail: os.time() not os.clock() -- clock is CPU time, not wall seconds
    local remaining = COOLDOWN - (os.time() - last_mount)
    if remaining > 0 then
        print(chat.header(addon.name):append(chat.message(('Locked out for %ds'):format(remaining))))
        return
    end

    last_mount = os.time()
    AshitaCore:GetChatManager():QueueCommand(1, '/mount ' .. config.mount)
end)

ashita.events.register('load', 'load_cb', function ()
    print(chat.header(addon.name):append(chat.message('Loaded. /ride toggles ' .. config.mount)))
end)
