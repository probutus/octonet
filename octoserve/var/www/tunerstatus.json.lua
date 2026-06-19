#!/usr/bin/lua

-- Richtigen HTTP-Header für JSON senden
print("Content-Type: application/json")
print("Pragma: no-cache")
print("Cache-Control: no-cache\n")

print("{\"TunerList\": [")

local max_frontends = 8
local tuner_entries = {}

for i = 0, (max_frontends - 1) do
    -- Wir rufen femon ganz normal auf (OHNE timeout-Kombination)
    local cmd = string.format("femon -H -a 0 -f %d -c 1 2>/dev/null", i)
    local handle = io.popen(cmd)
    
    local status = "Inactive"
    local lock = "false"
    local strength = 0
    local snr = 0
    local quality = 0
    local level = 0

    -- SICHERHEITS-GUARD: Zählt die gelesenen Zeilen pro Tuner
    local line_count = 0

    while true do
        local line = handle:read("*l")
        line_count = line_count + 1

        -- 1. NOTBREMSE: Wenn die Pipe leer ist oder femon mehr als 10 Zeilen 
        -- Fehlermeldungen ausgibt, brechen wir die Schleife sofort hart ab!
        if not line or line_count > 10 then 
            break 
        end 

        -- 2. VERARBEITUNG DER STATUSZEILE:
        if string.match(line, "status") then
            if string.match(line, "FE_HAS_LOCK") then
                status = "Active"
                lock = "true"
                quality = 100
                level = 224
                
                local sig_pct = line:match("signal%s+(%d+)%%")
                local snr_pct = line:match("snr%s+(%d+)%%")
                
                if sig_pct then
                    strength = -25000 + ((tonumber(sig_pct) - 80) * 125)
                else
                    strength = -25060
                end
                
                if snr_pct then
                    snr = tonumber(snr_pct) * 204
                else
                    snr = 15110
                end
            else
                -- Signalzeile ohne Lock gefunden -> Tuner ist Inactive
                status = "Inactive"
                lock = "false"
                strength = 0
                snr = 0
                quality = 0
                level = 0
            end
            break -- Statuszeile erfolgreich verarbeitet
        end
    end
    handle:close()

    local json_line = string.format(
        "{\"Input\":\"%d\",\"Status\":\"%s\",\"Lock\":%s,\"Strength\":%d,\"SNR\":%d,\"Quality\":%d,\"Level\":%d}",
        i, status, lock, strength, snr, quality, level
    )
    
    table.insert(tuner_entries, json_line)
end

-- JSON-Array lückenlos ausgeben
for idx, entry in ipairs(tuner_entries) do
    io.stdout:write(entry)
    if idx < #tuner_entries then 
        io.stdout:write(",\n") 
    else 
        io.stdout:write("\n") 
    end
end

print("]}")

