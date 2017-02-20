
-- Taken from bb template
if CreepCamps == nil then
    DebugPrint ( '[creeps/spawner] creating new CreepCamps object' )
    CreepCamps = class({})
end

--creep power level is from CREEP_POWER_LEVEL_MIN to CREEP_POWER_LEVEL_MAX
local CreepPowerLevel = 1.0

-- how often we spawn creeps
local CreepSpawnInterval = 60.0

--creep properties enumerations
local NAME_ENUM = 1
local HEALTH_ENUM = 2
local MANA_ENUM = 3
local DAMAGE_ENUM = 4
local ARMOR_ENUM = 5
local GOLD_BOUNTY_ENUM = 6
local EXP_BOUNTY_ENUM = 7

-- we want to set a timer to spawn creeps
-- the timer scans the map for all supported creep camps and spawns the creeps
-- profit

function CreepCamps:Init ()
  DebugPrint ( '[creeps/spawner] Initialize' )
  CreepCamps = self
  Timers:CreateTimer(Dynamic_Wrap(CreepCamps, 'CreepSpawnTimer'))
end

function CreepCamps:SetPowerLevel (powerLevel)
  CreepPowerLevel = powerLevel
end

function CreepCamps:CreepSpawnTimer ()
  -- scan for creep camps and spawn them
  -- DebugPrint('[creeps/spawner] Spawning creeps')
  local camps = Entities:FindAllByName('creep_camp')
  for _,camp in pairs(camps) do
    CreepCamps:DoSpawn(camp:GetAbsOrigin(), camp:GetIntAttr('CreepType'), camp:GetIntAttr('CreepMax'))
  end

  CreepCamps:UpgradeCreeps()

  return CreepSpawnInterval
end

function CreepCamps:UpgradeCreeps ()
  -- upgrade creeps power level every time it triggers
  CreepCamps:SetPowerLevel(CreepPowerLevel + 1)
end

function CreepCamps:DoSpawn (location, difficulty, maximumUnits)
  local creepCategory = CreepTypes[difficulty]
  local creepGroup = creepCategory[math.random(#creepCategory)]
  for i=1, #creepGroup do
    CreepCamps:SpawnCreepInCamp (location, creepGroup[i], maximumUnits)
  end
end
function CreepCamps:SpawnCreepInCamp (location, creepProperties, maximumUnits)
  if creepProperties == nil then
    DebugPrint ('[creeps/spawner] unknown creep type ')
    return false
  end

  -- ( iTeamNumber, vPosition, hCacheUnit, flRadius, iTeamFilter, iTypeFilter, iFlagFilter, iOrder, bCanGrowCache )
  local units = FindUnitsInRadius(DOTA_TEAM_NEUTRALS,
    location,
    nil,
    1000,
    DOTA_UNIT_TARGET_TEAM_FRIENDLY,
    DOTA_UNIT_TARGET_CREEP,
    DOTA_UNIT_TARGET_FLAG_NONE,
    FIND_ANY_ORDER,
    false)

  creepProperties = CreepCamps:AdjustCreepPropertiesByPowerLevel( creepProperties, CreepPowerLevel )

  if (maximumUnits and maximumUnits <= #units)
  then
    -- DebugPrint('[creeps/spawner] Too many creeps in camp, not spawning more')
    for _,unit in pairs(units) do
      local unitProperties = CreepCamps:GetCreepProperties(unit)
      local distributedScale = 1.0 / maximumUnits

      unitProperties = CreepCamps:AddCreepPropertiesWithScale(unitProperties, 1.0, creepProperties, distributedScale)
      CreepCamps:SetCreepPropertiesOnHandle(unit, unitProperties)
    end
    return false
  end

  local creepHandle = CreateUnitByName(creepProperties[NAME_ENUM], location, true, nil, nil, DOTA_TEAM_NEUTRALS)

  if creepHandle ~= nil then
    CreepCamps:SetCreepPropertiesOnHandle(creepHandle, creepProperties)
    creepHandle.Is_ItemDropEnabled = true
  end

  return true
end

function CreepCamps:GetCreepProperties(creepHandle)
  local creepProperties = {}

  creepProperties[HEALTH_ENUM] = creepHandle:GetMaxHealth()
  creepProperties[MANA_ENUM] = creepHandle:GetMana()
  creepProperties[DAMAGE_ENUM] = (creepHandle:GetBaseDamageMin() + creepHandle:GetBaseDamageMax()) / 2
  creepProperties[ARMOR_ENUM] = creepHandle:GetPhysicalArmorBaseValue()
  creepProperties[GOLD_BOUNTY_ENUM] = (creepHandle:GetMinimumGoldBounty() + creepHandle:GetMaximumGoldBounty()) / 2
  creepProperties[EXP_BOUNTY_ENUM] = creepHandle:GetDeathXP()

  return creepProperties
end

function CreepCamps:AdjustCreepPropertiesByPowerLevel( creepProperties, powerLevel )
  local adjustedCreepProperties = {}

  adjustedCreepProperties[NAME_ENUM] = creepProperties[NAME_ENUM]
  adjustedCreepProperties[HEALTH_ENUM] = creepProperties[HEALTH_ENUM] * GetPowerLevelPropertyMultiplier(HEALTH_ENUM, powerLevel)
  adjustedCreepProperties[MANA_ENUM] = creepProperties[MANA_ENUM] * GetPowerLevelPropertyMultiplier(MANA_ENUM, powerLevel)
  adjustedCreepProperties[DAMAGE_ENUM] = creepProperties[DAMAGE_ENUM] * GetPowerLevelPropertyMultiplier(DAMAGE_ENUM, powerLevel)
  adjustedCreepProperties[ARMOR_ENUM] = creepProperties[ARMOR_ENUM] * GetPowerLevelPropertyMultiplier(ARMOR_ENUM, powerLevel)
  adjustedCreepProperties[GOLD_BOUNTY_ENUM] = creepProperties[GOLD_BOUNTY_ENUM] * GetPowerLevelPropertyMultiplier(GOLD_BOUNTY_ENUM, powerLevel)
  adjustedCreepProperties[EXP_BOUNTY_ENUM] = creepProperties[EXP_BOUNTY_ENUM] * GetPowerLevelPropertyMultiplier(EXP_BOUNTY_ENUM, powerLevel)

  return adjustedCreepProperties
end

function CreepCamps:AddCreepPropertiesWithScale( propertiesOne, scaleOne, propertiesTwo, scaleTwo )
  local addedCreepProperties = {}

  addedCreepProperties[HEALTH_ENUM] = propertiesOne[HEALTH_ENUM] * scaleOne + propertiesTwo[HEALTH_ENUM] * scaleTwo
  addedCreepProperties[MANA_ENUM] = propertiesOne[MANA_ENUM] * scaleOne + propertiesTwo[MANA_ENUM] * scaleTwo
  addedCreepProperties[DAMAGE_ENUM] = propertiesOne[DAMAGE_ENUM] * scaleOne + propertiesTwo[DAMAGE_ENUM] * scaleTwo
  addedCreepProperties[ARMOR_ENUM] = propertiesOne[ARMOR_ENUM] * scaleOne + propertiesTwo[ARMOR_ENUM] * scaleTwo
  addedCreepProperties[GOLD_BOUNTY_ENUM] = propertiesOne[GOLD_BOUNTY_ENUM] * scaleOne + propertiesTwo[GOLD_BOUNTY_ENUM] * scaleTwo
  addedCreepProperties[EXP_BOUNTY_ENUM] = propertiesOne[EXP_BOUNTY_ENUM] * scaleOne + propertiesTwo[EXP_BOUNTY_ENUM] * scaleTwo

  return addedCreepProperties
end

function CreepCamps:SetCreepPropertiesOnHandle(creepHandle, creepProperties)
  --HEALTH
  local currentHealthMissing = creepHandle:GetMaxHealth() - creepHandle:GetHealth()
  local targetHealth = creepProperties[HEALTH_ENUM]

  if currentHealthMissing > 0 then
    targetHealth = creepProperties[HEALTH_ENUM] - currentHealthMissing
  end

  creepHandle:SetBaseMaxHealth(math.ceil(creepProperties[HEALTH_ENUM]))
  creepHandle:SetMaxHealth(math.ceil(creepProperties[HEALTH_ENUM]))
  creepHandle:SetHealth(math.ceil(targetHealth))

  --MANA
  creepHandle:SetMana(math.ceil(creepProperties[MANA_ENUM]))

  --DAMAGE
  creepHandle:SetBaseDamageMin(math.ceil(creepProperties[DAMAGE_ENUM]))
  creepHandle:SetBaseDamageMax(math.ceil(creepProperties[DAMAGE_ENUM]))

  --ARMOR
  creepHandle:SetPhysicalArmorBaseValue(creepProperties[ARMOR_ENUM])

  --GOLD BOUNTY
  creepHandle:SetMinimumGoldBounty(math.ceil(creepProperties[GOLD_BOUNTY_ENUM]))
  creepHandle:SetMaximumGoldBounty(math.ceil(creepProperties[GOLD_BOUNTY_ENUM]))

  --EXP BOUNTY
  creepHandle:SetDeathXP(math.ceil(creepProperties[EXP_BOUNTY_ENUM]))
end

function GetPowerLevelPropertyMultiplier( property_enum, powerLevel )
  local powerLevelPropertyMultiplier = 1
  local lowerIndex = 1
  local higherIndex = #CreepPowerTable

  for i=1, #CreepPowerTable do
    if CreepPowerTable[i][1] <= powerLevel then
      lowerIndex = i
    end
    if CreepPowerTable[i][1] >= powerLevel then
      higherIndex = i
      break
    end
  end

  if lowerIndex == higherIndex then
    powerLevelPropertyMultiplier = CreepPowerTable[lowerIndex][property_enum]
  else
    local lowerIndexLevel = CreepPowerTable[lowerIndex][1]
    local higherIndexLevel = CreepPowerTable[higherIndex][1]

    local levelRatio = (powerLevel - lowerIndexLevel) / (higherIndexLevel - lowerIndexLevel)

    local lowerIndexValue = CreepPowerTable[lowerIndex][property_enum]
    local higherIndexValue = CreepPowerTable[higherIndex][property_enum]

    powerLevelPropertyMultiplier = lowerIndexValue + levelRatio * (higherIndexValue - lowerIndexValue)
  end

  return powerLevelPropertyMultiplier
end
