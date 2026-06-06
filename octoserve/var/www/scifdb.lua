#!/usr/bin/lua

-- 1. SLAXML-Bibliothek laden
local SLAXML = require 'slaxdom'

-- 2. Absoluter Pfad zur XML-Datenbank im Webroot erzwingen!
local xml_file = '/var/www/SCIFDataBase.xml'
local f = io.open(xml_file, "r")

if not f then
    -- Ausfallsicherer CGI-Header für Fehlermeldung
    print("Status: 500 Internal Server Error")
    print("Content-Type: text/html\n")
    print("<h2>Fehler: SCIFDataBase.xml nicht gefunden unter " .. xml_file .. "!</h2>")
    os.exit()
end

local SCIFDataBase = f:read("*a")
f:close()

-- XML parsen und DOM-Baum aufbauen
local dom = SLAXML:dom(SCIFDataBase, { simple=false, stripWhitespace=true })

-- Standardkonformer HTTP-Header für lighttpd CGI
print("Content-Type: application/x-javascript")
print("Pragma: no-cache")
print("Cache-Control: no-cache\n") -- Die Leerzeile beendet die Header

-- Datenstrukturen initialisieren
local ManufacturerList = {}
local ManufacturerArray = {}
local ManufacturerCount = 0

-- DOM-Baum durchlaufen und Hersteller-Daten extrahieren
for _, child in ipairs(dom.kids) do
  if child.name == "SCIFDataBase" then
    for _, unit in ipairs(child.kids) do
      if unit.name == "OutdoorUnit" then
        local Name = unit.attr["Name"] or ""
        local Manufacturer = unit.attr["Manufacturer"] or ""
        local Type = unit.attr["Type"] or "LNB"
        local Protocol = unit.attr["Protocol"] or "EN50494"
        
        local CurManu = ManufacturerList[Manufacturer]
        if not CurManu then
          CurManu = { UnitList = {}, UnitCount = 0, Name = Manufacturer }
          ManufacturerCount = ManufacturerCount + 1
          ManufacturerList[Manufacturer] = CurManu
          ManufacturerArray[ManufacturerCount] = CurManu
        end
        
        CurManu.UnitCount = CurManu.UnitCount + 1
        local CurUnit = { Name = Name, Type = Type, Protocol = Protocol, Frequencies = {} } 
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

-- =====================================================================
-- JAVASCRIPT-OUTPUT FÜR DEN BROWSER (STDOUT)
-- =====================================================================
print("ManufacturerList = new Array();")

-- WICHTIG: Ein separater Zähler, der strikt bei 0 für JavaScript beginnt
local m_idx = 0

for _, CurManu in ipairs(ManufacturerArray) do
  print("")
  print(string.format("ManufacturerList[%d] = new Object();", m_idx))
  print(string.format("ManufacturerList[%d].Name = \"%s\";", m_idx, CurManu.Name))
  print(string.format("ManufacturerList[%d].UnitList = new Array();", m_idx))

  local u_idx = 0
  for _, CurUnit in ipairs(CurManu.UnitList) do
    print(string.format("ManufacturerList[%d].UnitList[%d] = new Object();", m_idx, u_idx))
    print(string.format("ManufacturerList[%d].UnitList[%d].Name = \"%s\";", m_idx, u_idx, CurUnit.Name))
    print(string.format("ManufacturerList[%d].UnitList[%d].Protocol = \"%s\";", m_idx, u_idx, CurUnit.Protocol))
    print(string.format("ManufacturerList[%d].UnitList[%d].Frequencies = new Array();", m_idx, u_idx))
    
    local f_idx = 0
    for _, Frequency in ipairs(CurUnit.Frequencies) do
      print(string.format("ManufacturerList[%d].UnitList[%d].Frequencies[%d] = %d;", m_idx, u_idx, f_idx, Frequency))
      f_idx = f_idx + 1
    end
    u_idx = u_idx + 1
  end
  
  m_idx = m_idx + 1
end

print("") -- Abschluss-Newline

