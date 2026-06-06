#!/usr/bin/lua

-- 1. Hilfsfunktion: String-Trimming für Leerzeichen und Newlines
local function trim(s)
    if not s then return "" end
    return s:match("^%s*(.-)%s*$")
end

-- 2. Dynamische Erkennung der Tuner-Hardware via Sysfs (Sehr schnell im RAM)
local function get_active_tuners()
    local tuners = {}
    local adapter_idx = 0
    
    -- Wir scannen die DVB-Frontend-Knoten im Kernel
    while true do
        local frontend_path = string.format("/sys/class/dvb/dvb0.frontend%d/type", adapter_idx)
        local f = io.open(frontend_path, "r")
        
        if not f then
            -- Keine weiteren Frontend-Knoten mehr im System vorhanden
            break
        end
        
        local t_type = trim(f:read("*l"))
        f:close()
        
        -- Mapping des Kernel-Typs auf die herstellerspezifischen Masken-Werte
        local octo_type = 96 -- Standard/Fallback: DVB-S2
        if t_type == "cable" then
            octo_type = 64
        elseif t_type == "terrestrial" then
            octo_type = 112
        end
        
        table.insert(tuners, octo_type)
        adapter_idx = adapter_idx + 1
    end
    
    -- Hardwarerobuster Fallback auf 8 Standard-Sat-Tuner, falls das Sysfs leer sein sollte
    if #tuners == 0 then
        for i = 1, 8 do table.insert(tuners, 96) end
    end
    
    return tuners
end

-- =====================================================================
-- JAVASCRIPT / JSON-GENERIERUNG (STDOUT)
-- =====================================================================

-- Richtigen HTTP-Header für JSON senden
print("Content-Type: application/json")
print("Pragma: no-cache")
print("Cache-Control: no-cache\n")

print("{\"TunerList\": [")

local active_tuners = get_active_tuners()

-- Dynamischer Aufbau des JSON-Arrays basierend auf den Kernel-Knoten
for idx, tuner_type in ipairs(active_tuners) do
    local json_idx = idx - 1 -- JSON/JavaScript-Arrays starten bei Index 0
    
    -- Das Unicable-Menü benötigt hier nur den korrekten Typ. 
    -- Der Status wird im Konfigurationsmodus sicherheitshalber auf "Inactive" gesetzt.
    local json_line = string.format(
        "{\"Input\":\"%d\",\"Status\":\"Inactive\",\"Lock\":false,\"Strength\":0,\"SNR\":0,\"Quality\":0,\"Level\":0,\"Type\":%d}",
        json_idx, tuner_type
    )
    
    io.stdout:write(json_line)
    
    if idx < #active_tuners then
        io.stdout:write(",\n")
    else
        io.stdout:write("\n")
    end
end

print("]}")

