require('NPCs/MainCreationMethods');

local TRAIT_NAME = "tourette-syndrome"
local phrasesCount

local function countPhrases()
    phrasesCount = nil

    for i = 100, 0, -1 do
        if getTextOrNull("UI_TouretteSyndrome_phrase_" .. i) ~= nil then
            phrasesCount = i
            print("Found " .. phrasesCount .. " phrases for Tourette Syndrome trait.")
            break
        end
    end
end

Events.OnGameBoot.Add(function()
    TraitFactory.addTrait(TRAIT_NAME, getText("UI_TouretteSyndrome_traitName"), -10,
        getText("UI_TouretteSyndrome_traitDescription"), false, false);

    countPhrases()
end);

local function checkPlace()
    local player = getPlayer()

    if player:isDead() then
        return false
    end

    if player:isAsleep() then
        return false
    end

    if player:isSeatedInVehicle() then
        if player:getVehicle():windowsOpen() > 0 then
            return true
        end

        return false
    end

    return true
end

local function checkTime()
    return ZombRand(100) < SandboxVars.TouretteSyndrome.TicChance
end

local function shouldTic()
    return checkPlace() and checkTime()
end

local function getTicParams()
    local radius = ZombRandBetween(SandboxVars.TouretteSyndrome.MinRadius, SandboxVars.TouretteSyndrome.MaxRadius + 1)
    print(radius)

    return {
        radius = radius,
        shout = radius >= SandboxVars.TouretteSyndrome.ShoutThreshold
    }
end

local function performProfanityFilter(phrase)
    local filter = SandboxVars.TouretteSyndrome.ProfanityFilter
    if filter and filter ~= "" then
        local whitelist = "@#$%&*"
        local words = {}
        for word in string.gmatch(filter, '([^,]+)') do
            word = word:gsub("^%s*(.-)%s*$", "%1")
            if word ~= "" then
                table.insert(words, word)
            end
        end

        local lower_phrase = phrase:lower()
        for _, badword in ipairs(words) do
            local pattern = badword:gsub("([^%w])", "%%%1")
            local lower_pattern = pattern:lower()
            local start = 1
            while true do
                local s, e = lower_phrase:find(lower_pattern, start, true)
                if not s then
                    break
                end
                local match = phrase:sub(s, e)
                local res = {}
                for i = 1, #match do
                    local idx = ZombRand(1, #whitelist + 1)
                    res[i] = whitelist:sub(idx, idx)
                end
                phrase = phrase:sub(1, s - 1) .. table.concat(res) .. phrase:sub(e + 1)
                lower_phrase = phrase:lower()
                start = s + #res
            end
        end
    end

    return phrase
end

local function performTic()
    if phrasesCount == nil then
        return
    end

    local player = getPlayer()
    local params = getTicParams()
    local phrase = getText("UI_TouretteSyndrome_phrase_" .. ZombRand(1, phrasesCount))

    if SandboxVars.TouretteSyndrome.ProfanityFilterEnabled then
        phrase = performProfanityFilter(phrase);
    end

    if params.shout then
        player:SayShout(phrase:upper())
        player:playerVoiceSound("ShoutHey");
    else
        player:Say(phrase)
        player:playerVoiceSound("WhisperHey");
    end

    addSound(player, player:getX(), player:getY(), player:getZ(), params.radius, params.radius);
end

Events.EveryOneMinute.Add(function()
    if not getPlayer():HasTrait(TRAIT_NAME) then
        return
    end

    if not shouldTic() then
        return
    end

    performTic()
end)
