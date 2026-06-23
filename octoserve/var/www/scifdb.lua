#!/usr/bin/lua
local target_file = '/var/www/scifdb_cache.js'

-- CGI-Header senden, falls das Iframe anklopft
print("Content-Type: text/html")
print("Pragma: no-cache")
print("Cache-Control: no-cache\n")

-- 1. PRÜFUNG: Wenn die Datei schon existiert und kein expliziter Generierungsbefehl vorliegt, beenden
local query = os.getenv("QUERY_STRING") or ""
local f_check = io.open(target_file, "r")
if f_check and not string.match(query, "generate") then
    f_check:close()
    os.exit()
end
if f_check then f_check:close() end

-- 2. GENERIERUNG: XML einlesen und parsen
local SLAXML = require 'slaxdom'
local xml_file = '/var/www/SCIFDataBase.xml'
local f = io.open(xml_file, "r")
if not f then
    -- Minimal-Dummy erzeugen, falls XML fehlt
    local wf = io.open(target_file, "w")
    if wf then wf:write("ManufacturerList = new Array();\n") wf:close() end
    os.exit()
end
local SCIFDataBase = f:read("*a")
f:close()

local dom = SLAXML:dom(SCIFDataBase, { simple=false, stripWhitespace=true })
local ManufacturerList = {}
local ManufacturerArray = {}
local ManufacturerCount = 0

for _, child in ipairs(dom.kids) do
    if child.name == "SCIFDataBase" then
        for _, unit in ipairs(child.kids) do
            if unit.name == "OutdoorUnit" then
                local Name = unit.attr["Name"] or ""
                local Manufacturer = unit.attr["Manufacturer"] or ""
                local Protocol = unit.attr["Protocol"] or "EN50494"
                local CurManu = ManufacturerList[Manufacturer]
                if not CurManu then
                    CurManu = { UnitList = {}, UnitCount = 0, Name = Manufacturer }
                    ManufacturerCount = ManufacturerCount + 1
                    ManufacturerList[Manufacturer] = CurManu
                    ManufacturerArray[ManufacturerCount] = CurManu
                end
                CurManu.UnitCount = CurManu.UnitCount + 1
                local CurUnit = { Name = Name, Protocol = Protocol, Frequencies = {} }
                CurManu.UnitList[CurManu.UnitCount] = CurUnit
                local fcount = 0
                for _, Frequency in ipairs(unit.kids) do
                    if Frequency.name == "UBSlot" then
                        fcount = fcount + 1
                        CurUnit.Frequencies[fcount] = tonumber(Frequency.attr["Frequency"]) or 0
                    end
                end
            end
        end
    end
end

local out = {}
table.insert(out, "ManufacturerList = new Array();\n")
local m_idx = 0
for _, CurManu in ipairs(ManufacturerArray) do
    table.insert(out, string.format("ManufacturerList[%d] = new Object();\n", m_idx))
    table.insert(out, string.format("ManufacturerList[%d].Name = \"%s\";\n", m_idx, CurManu.Name))
    table.insert(out, string.format("ManufacturerList[%d].UnitList = new Array();\n", m_idx))
    local u_idx = 0
    for _, CurUnit in ipairs(CurManu.UnitList) do
        table.insert(out, string.format("ManufacturerList[%d].UnitList[%d] = new Object();\n", m_idx, u_idx))
        table.insert(out, string.format("ManufacturerList[%d].UnitList[%d].Name = \"%s\";\n", m_idx, u_idx, CurUnit.Name))
        table.insert(out, string.format("ManufacturerList[%d].UnitList[%d].Protocol = \"%s\";\n", m_idx, u_idx, CurUnit.Protocol))
        table.insert(out, string.format("ManufacturerList[%d].UnitList[%d].Frequencies = new Array();\n", m_idx, u_idx))
        for f_idx, Frequency in ipairs(CurUnit.Frequencies) do
            table.insert(out, string.format("ManufacturerList[%d].UnitList[%d].Frequencies[%d] = %d;\n", m_idx, u_idx, f_idx-1, Frequency))
        end
        u_idx = u_idx + 1
    end
    m_idx = m_idx + 1
end

-- VIRTUELLEN CUSTOM-EINTRAG ANHÄNGEN
table.insert(out, string.format("ManufacturerList[%d] = new Object();\n", m_idx))
table.insert(out, string.format("ManufacturerList[%d].Name = \"-- Benutzerdefiniert --\";\n", m_idx))
table.insert(out, string.format("ManufacturerList[%d].UnitList = new Array();\n", m_idx))
table.insert(out, string.format("ManufacturerList[%d].UnitList = new Object();\n", m_idx))
table.insert(out, string.format("ManufacturerList[%d].UnitList.Name = \"Manuelle Konfiguration\";\n", m_idx))
table.insert(out, string.format("ManufacturerList[%d].UnitList.Protocol = \"EN50494\";\n", m_idx))
table.insert(out, string.format("ManufacturerList[%d].UnitList.Frequencies = new Array();\n", m_idx))

local final_js = table.concat(out)

-- Cache-Datei fest in das Webverzeichnis schreiben
local wcf = io.open(target_file, "w")
if wcf then
    wcf:write(final_js)
    wcf:close()
end

-- Iframe signalisieren, dass alles fertig ist
print("<html><body>Done</body></html>")

