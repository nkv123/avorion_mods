# avorion_mods
## added files
1. data/scripts/entity/ai/lazymine.lua 
1. data/scripts/entity/ai/lazymineall.lua
1. data/scripts/entity/ai/lazysalvage.lua
1. data/scripts/entity/ai/mineall.lua
1. data/scripts/entity/ai/preparefortransfer.lua -- unfinished

## modded files

1. data/scripts/entity/craftorders.lua

## existing mods

1. loglevels from https://github.com/dirtyredz

# Script explanation

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
  
