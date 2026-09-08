-- Ride - one command to mount/dismount

addon.name    = 'Ride'
addon.author  = 'Seekey'
addon.version = '1.1'
addon.desc    = 'Toggle your mount with /ride'
addon.link    = 'https://github.com/seekey13/Ride'

require('common')
local chat = require('chat')
local settings = require('settings')

local MOUNTED_BUFF = 252
local COOLDOWN = 60
local CONFIRM_WINDOW = 10  -- stop waiting for the buff after this many seconds

-- Mount key items run contiguously from 3072, so list index N is key item 3071 + N.
local KEYITEM_BASE = 3072
local MOUNTS = {
    'Chocobo', 'Raptor', 'Tiger', 'Crab', 'Red crab', 'Bomb',
    'Sheep', 'Morbol', 'Crawler', 'Fenrir', 'Beetle', 'Moogle',
    'Magic pot', 'Tulfaire', 'Warmachine', 'Xzomit', 'Hippogryph', 'Spectral chair',
    'Spheroid', 'Omega', 'Coeurl', 'Goobbue', 'Raaz', 'Levitus',
    'Adamantoise', 'Dhalmel', 'Doll', 'Golden Bomb', 'Buffalo', 'Wivre',
    'Red Raptor', 'Iron Giant', 'Byakko', 'Noble Chocobo', 'Ixion', 'Phuabo',
}

local config = settings.load(T{ mount = 'Raptor' })
settings.register('settings', 'settings_update', function (s)
    if s ~= nil then config = s end
end)

local last_mount = 0  -- os.time() the mount buff was confirmed after our /mount
local pending    = 0  -- os.time() of a /mount we issued but have not confirmed

-- ponytail: buff array is fixed at 32 slots; 255/0 are empty markers
local function is_mounted()
    local player = AshitaCore:GetMemoryManager():GetPlayer()
    local buffs = player and player:GetBuffs()
    if not buffs then return false end
    for i = 1, 32 do
        if buffs[i] == MOUNTED_BUFF then return true end
    end
    return false
end

-- Returns a mount this character has unlocked, or nil if they own none.
-- ponytail: rebuilt per call; 36 key item reads is nothing next to a frame
local function random_mount()
    local player = AshitaCore:GetMemoryManager():GetPlayer()
    if not player then return nil end
    local owned = {}
    for i, name in ipairs(MOUNTS) do
        if player:HasKeyItem(KEYITEM_BASE + i - 1) then
            owned[#owned + 1] = name
        end
    end
    if #owned == 0 then return nil end
    return owned[math.random(#owned)]
end

-- Only a confirmed buff starts the lockout, so a /mount the game refuses costs nothing.
-- ponytail: runs per frame but only does work while a mount is pending
ashita.events.register('d3d_present', 'present_cb', function ()
    if pending == 0 then return end
    if is_mounted() then
        last_mount = os.time()
        pending = 0
    elseif os.time() - pending > CONFIRM_WINDOW then
        pending = 0  -- mount never landed; no lockout
    end
end)

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

    if pending ~= 0 then return end  -- a /mount is already in flight

    -- ponytail: os.time() not os.clock() -- clock is CPU time, not wall seconds
    local remaining = COOLDOWN - (os.time() - last_mount)
    if remaining > 0 then
        print(chat.header(addon.name):append(chat.message(('Locked out for %ds'):format(remaining))))
        return
    end

    -- 'Random' is a sentinel, not a mount name: reroll on every /ride.
    local mount = config.mount
    if mount:lower() == 'random' then
        mount = random_mount()
        if mount == nil then
            print(chat.header(addon.name):append(chat.message('No mounts unlocked on this character.')))
            return
        end
    end

    pending = os.time()
    -- ponytail: %q quotes unconditionally; harmless on single-word names
    AshitaCore:GetChatManager():QueueCommand(1, ('/mount %q'):format(mount))
end)

ashita.events.register('load', 'load_cb', function ()
    math.randomseed(os.time())
    print(chat.header(addon.name):append(chat.message('Loaded. /ride toggles ' .. config.mount)))
end)
