# Ride

Ashita v4 addon. One command to mount and dismount.

## Install

Drop `Ride.lua` in `Ashita/addons/Ride/`, then `/addon load Ride`.

## Usage

| Command | Does |
| --- | --- |
| `/ride` | Mounted? `/dismount`. Not mounted? `/mount <your mount>`. |
| `/ride <name>` | Set the mount to use. Saved between sessions. |
| `/ride Random` | Roll a different unlocked mount every `/ride`. |
| `/ride list` | Show the mounts this character has unlocked. |

Default mount is `Random`. `Random` is a sentinel, not a mount name - it picks fresh each time from the mounts this character has unlocked.

## Notes

- 60 second lockout, started only once the mount buff is confirmed. A `/mount` the game refuses (town, dungeon, combat, bad mount name) costs you nothing. Dismounting is never blocked.
- Mount status is read from your buffs each time, so the 30 minute buff expiry needs no handling.
- The unlocked-mount list comes from packet `0x0AE`, which the server sends on zone. Load the addon and `/ride Random` before zoning and it has nothing to pick from - zone once and it fills in. `/ride list` shows what it has.
- Mount names are read from the client's own resource table rather than a hardcoded list, so custom server mounts work. Key items 3072+ carry the same data on retail, but `HasKeyItem` reads nothing on a modified client, so the packet is the only source that works everywhere.
