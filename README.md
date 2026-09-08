# Ride

Ashita v4 addon. One command to mount and dismount.

## Install

Drop `Ride.lua` in `Ashita/addons/Ride/`, then `/addon load Ride`.

## Usage

| Command | Does |
| --- | --- |
| `/ride` | Mounted? `/dismount`. Not mounted? `/mount <your mount>`. |
| `/ride <name>` | Set the mount to use. Saved between sessions. |

Default mount is `Raptor`.

## Notes

- 60 second lockout, started only once the mount buff is confirmed. A `/mount` the game refuses (town, dungeon, combat, bad mount name) costs you nothing. Dismounting is never blocked.
- Mount status is read from your buffs each time, so the 30 minute buff expiry needs no handling.
