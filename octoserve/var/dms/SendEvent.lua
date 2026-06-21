#!/usr/bin/lua

local socket = require("socket")
local mime = require("mime")
local url = require("socket.url")

if #arg ~= 4 then
  os.exit(1)
end

local path, uuid, seq, b64 = unpack(arg)

local values = mime.unb64(b64)
if values == "nil" then
  values = ""
end

local evnt = '<?xml version="1.0" encoding="utf-8"?>'.."\r\n"
          .. '<a:propertyset xmlns:a="urn:schemas-upnp-org:event-1-0/">'.."\r\n"
          .. "<a:property>\r\n"
          .. values
          .. "</a:property>\r\n"
          .. "</a:propertyset>\r\n"

-- KORREKTUR: Nicht-gieriges Pattern ".-" verwendet, um mehrere URLs sauber zu trennen
for p in string.gmatch(path, "<(.-)>") do

  local parsed_url = url.parse(p)
  
  -- KORREKTUR: Sicherheitsprüfung, ob das Parsing erfolgreich war
  if parsed_url and parsed_url.host then
    local ip = parsed_url.host
    local port = parsed_url.port or 80 -- Fallback auf Standard-HTTP-Port, falls nicht angegeben
    local path_req = parsed_url.path or "/"

    if port and port ~= "0" then
      
      local r = "NOTIFY " .. path_req .. " HTTP/1.1\r\n"
              .. "Host: " .. ip .. ":" .. port .. "\r\n"
              .. "Content-Type: text/xml; charset=\"utf-8\"\r\n"
              .. "Content-Length: " .. string.format("%d", #evnt) .. "\r\n"
              .. "NT: upnp:event\r\n"
              .. "NTS: upnp:propchange\r\n"
              .. "SID: uuid:" .. uuid .. "\r\n"
              .. "SEQ: " .. seq .. "\r\n"
              .. "\r\n"
              .. evnt    
      
      local tcp = socket.tcp()
      tcp:settimeout(2)
      
      if tcp:connect(ip, port) then
        tcp:send(r)
        tcp:receive("*l") -- Bestätigung des Clients abwarten
        tcp:close()
        break -- Bei Erfolg abbrechen, da die Benachrichtigung zugestellt wurde
      end
      tcp:close()
    end
  end
end

