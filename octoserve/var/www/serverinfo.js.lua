#!/usr/bin/lua

-- =====================================================================
-- HILFSFUNKTIONEN
-- =====================================================================

-- Entfernt führende/nachfolgende Leerzeichen und Zeilenumbrüche
local function trim(s)
    if not s then return "" end
    return s:match("^%s*(.-)%s*$")
end

-- =====================================================================
-- SYSTEM-ABFRAGEN (SYSFS / PROC)
-- =====================================================================

-- 1. Dynamische BootID generieren
-- Liest die Kernel-UUID und wandelt den ersten Hex-Block in eine Ganzzahl um
local function get_boot_id()
    local f = io.open("/proc/sys/kernel/random/boot_id", "r")
    if f then
        local uuid = f:read("*l")
        f:close()
        local hex_part = uuid:match("^(%x+)")
        if hex_part then 
            return tonumber(hex_part, 16) 
        end
    end
    return 0 -- Sicherer Fallback
end

-- 2. Dynamische DeviceID aus dem ddbridge-Treiber lesen
local function get_device_id()
    local f = io.open("/sys/class/ddbridge/ddbridge0/devid0", "r")
    if f then
        local devid = f:read("*l")
        f:close()
        return tonumber(trim(devid),16) or 0
    end
    return 0 -- Fallback (Octonet Standard ID)
end

-- 3. Dynamische MAC-Adresse lesen
local function get_mac()
    local f = io.open("/sys/class/net/eth0/address", "r") -- Falls Bridge aktiv, ggf. br0 nutzen
    if f then
        local mac = f:read("*l")
        f:close()
        return trim(mac):lower()
    end
    return "00:00:00:00:00:00" -- Fallback
end

-- 4. Dynamische Erkennung der Tuner-Hardware via Sysfs
local function get_tuner_list()
    local tuners = {}
    local adapter_idx = 0
    
    -- Scanni-Schleife für DVB-Adapter im System
    while true do
        local frontend_path = string.format("/sys/class/dvb/dvb%d.frontend0/type", adapter_idx)
        local f = io.open(frontend_path, "r")
        
        if not f then
            -- Keine weiteren DVB-Adapter mehr im System gefunden
            break
        end
        
        local t_type = trim(f:read("*l"))
        f:close()
        
        -- Mapping des Kernel-Typs auf die Octonet-Masken-Werte
        local octo_type = 96 -- Standard: DVB-S2
        local octo_desc = "DVB-S/S2"
        
        if t_type == "cable" then
            octo_type = 64
            octo_desc = "DVB-C"
        elseif t_type == "terrestrial" then
            octo_type = 112
            octo_desc = "DVB-T2"
        end
        
        table.insert(tuners, { type = octo_type, desc = octo_desc })
        adapter_idx = adapter_idx + 1
    end
    
    -- Hardwarerobuster Fallback, falls Sysfs im Testzustand leer sein sollte
    if #tuners == 0 then
        for i = 1, 8 do
            table.insert(tuners, { type = 96, desc = "DVB-S/S2" })
        end
    end
    
    return tuners
end

-- =====================================================================
-- JAVASCRIPT-GENERIERUNG (STDOUT)
-- =====================================================================

-- Setzt den korrekten HTTP-Header für JavaScript-Dateien
print("Content-type: application/x-javascript\n")

local current_boot_id = get_boot_id()
local current_device_id = get_device_id()
local current_mac = get_mac()
local active_tuners = get_tuner_list()

print("Octoserve = new Object();")
print("Octoserve.Version = \"1.2.0\";")
print("Octoserve.BootID = " .. current_boot_id .. ";")
print("Octoserve.DeviceID = " .. current_device_id .. ";")
print("Octoserve.MAC = \"" .. current_mac .. "\";")

-- Setzt die DelsysMask anhand des ersten erkannten Tuners fest
if active_tuners and active_tuners[1] then
    print("Octoserve.DelsysMask = " .. active_tuners[1].type .. ";")
else
    print("Octoserve.DelsysMask = 96;")
end

print("Octoserve.TunerList = new Array();")

-- Dynamischer Aufbau des JS-Arrays für das Webinterface
for idx, tuner in ipairs(active_tuners) do
    local js_idx = idx - 1 -- JavaScript-Arrays beginnen bei Index 0
    print("Octoserve.TunerList[" .. js_idx .. "] = new Object();")
    print("Octoserve.TunerList[" .. js_idx .. "].Type = " .. tuner.type .. ";")
    print("Octoserve.TunerList[" .. js_idx .. "].Desc = \"" .. tuner.desc .. " \";")
end

