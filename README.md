# avorion_mods
## added files
1. data/scripts/entity/ai/lazymine.lua 
1. data/scripts/entity/ai/lazymineall.lua
1. data/scripts/entity/ai/lazysalvage.lua
1. data/scripts/entity/ai/mineall.lua
1. data/scripts/entity/ai/preparefortransfer.lua -- unfinished
1. data/scripts/commands/turrets.lua
1. data/scripts/commands/upgrades.lua
1. data/scripts/commands/uturrets.lua

## modded files

1. data/scripts/entity/craftorders.lua
1. data/scripts/lib/defaultscripts.lua
## existing mods

1. loglevels from https://github.com/dirtyredz

# Script explanation and changes

## lazymine 
highest priority is mining
first, check if there is an asteroid to mine, 
then, if there's no asteroid, check  if there is loot to collect.
## lazysalvage
highest priority is wrecking the wreckages
first, check if there is a wreckage to mine
then, if there's no wreckage, check if there is loot to collect
## lazymineall
check the sector for an asteroid
if there is one
highest priority is mining
first, check if there is an asteroid to mine
then, if there's no asteroid, check  if there is loot to collect
## mineall
check the sector for an asteroid
if there is one
highest priority is collecting the resources
first, check if there is loot to collect
then, if there's no loot, check if there is an asteroid to mine
## preparefortransfer
its not working what it should do is go to the front of player ship 2 km out and approuch until range is 0 so that transfer of wares is possable.

## turrets
adds 12 cannons, lasers, railguns plasmagun, lightningguns, teslaguns, pulseguns turrets
## uturrets
adds 12 mining, salvage, hull repair, shield repair turrets
## upgrades
adds 5 hyperspace, minining systems, tradeoverview, civiltcs, militarycts, scanboosters, radarboosters
## craftorders
added commands for lazy mine, lazy salvage, lazy mine all, mine all.
added command to add entitydbg.lua to player entities
## defaultscripts.lua
added entitydbg.lua to ships
added entitydbg.lua to stations


# usage
* for turrets type /turrets in console
* for uturrets type /uturrets in console
* for upgrades type /upgrades in console

