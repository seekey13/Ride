-- Ride - one command to mount/dismount

addon.name    = 'Ride'
addon.author  = 'Seekey'
addon.version = '1.1'
addon.desc    = 'Toggle your mount with /ride'
addon.link    = 'https://github.com/seekey13/Ride'

require('common')
local bit = require('bit')
local chat = require('chat')
local settings = require('settings')

local MOUNTED_BUFF = 252
local COOLDOWN = 60
local CONFIRM_WINDOW = 10  -- stop waiting for the buff after this many seconds

-- The server announces owned mounts in packet 0x0AE, sent on zone. Its whole
-- payload is a little-endian bitmask where bit N means mount id N is unlocked.
-- Key items 3072+ carry the same thing on retail, but HasKeyItem reads nothing
-- on a modified client, so the packet is the only source that works everywhere.
local MOUNT_LIST_PACKET = 0x0AE
local MASK_OFFSET = 4  -- e.data includes the 4-byte packet header
local MASK_BYTES = 8   -- 64 mount ids
local NO_LIST = 'No mount list yet -- zone once so the server sends it.'

local config = settings.load(T{ mount = 'Random' })
settings.register('settings', 'settings_update', function (s)
    if s ~= nil then config = s end
end)

local last_mount = 0  -- os.time() the mount buff was confirmed after our /mount
local pending    = 0  -- os.time() of a /mount we issued but have not confirmed
local owned      = {} -- mount names from the last 0x0AE; empty until we zone

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

local function mount_ids(data)
    local ids = {}
    for id = 0, MASK_BYTES * 8 - 1 do
        local value = data:byte(MASK_OFFSET + math.floor(id / 8) + 1)
        if bit.band(value, bit.lshift(1, id % 8)) ~= 0 then ids[#ids + 1] = id end
    end
    return ids
end

-- ponytail: self-check at load; payload with bit 0 and bit 9 set means ids 0 and 9.
do
    local ids = mount_ids(('\0'):rep(MASK_OFFSET) .. '\1\2' .. ('\0'):rep(MASK_BYTES - 2))
    assert(#ids == 2 and ids[1] == 0 and ids[2] == 9, 'mount_ids: bitmask parse broken')
end

ashita.events.register('packet_in', 'packet_in_cb', function (e)
    if e.id ~= MOUNT_LIST_PACKET then return end
    if #e.data < MASK_OFFSET + MASK_BYTES then return end

    local names = {}
    for _, id in ipairs(mount_ids(e.data)) do
        -- Names come from the client's own resource table, so custom server mounts
        -- (CatsEyeXI's Gyokko is id 50) resolve without hardcoding a list.
        -- Skip ids the client cannot name; /mount needs a name, not an id.
        local name = AshitaCore:GetResourceManager():GetString('mounts.names', id)
        if name and name ~= '' then names[#names + 1] = name end
    end
    owned = names
end)

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
        local arg = table.concat(args, ' ', 2)
        if arg:lower() == 'list' then
            local msg = #owned > 0 and table.concat(owned, ', ') or NO_LIST
            return print(chat.header(addon.name):append(chat.message(msg)))
        end
        config.mount = arg
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
        if #owned == 0 then return print(chat.header(addon.name):append(chat.message(NO_LIST))) end
        mount = owned[math.random(#owned)]
    end

    pending = os.time()
    -- ponytail: %q quotes unconditionally; harmless on single-word names
    AshitaCore:GetChatManager():QueueCommand(1, ('/mount %q'):format(mount))
end)

ashita.events.register('load', 'load_cb', function ()
    math.randomseed(os.time())
    print(chat.header(addon.name):append(chat.message('Loaded. /ride toggles ' .. config.mount)))
end)
