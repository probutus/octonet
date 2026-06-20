#!/usr/bin/lua

local socket = require("socket")
local url = require("socket.url")

local host = os.getenv("HTTP_HOST")
local proto = os.getenv("SERVER_PROTOCOL") or "HTTP/1.1"
local query = os.getenv("QUERY_STRING") or ""
local method = os.getenv("REQUEST_METHOD") or "GET"

local server_file = "/config/updateserver"
local server_bak = "/config/updateserver.bak"

function http_print(s)
  if s then
    io.stdout:write(tostring(s).."\r\n")
  else
    io.stdout:write("\r\n")
  end
end

function SendError(err, desc)
  http_print(proto.." "..err)
  http_print("Content-Type: text/html")
  http_print()
  local file = io.open("e404.html")
  if file then
    local tmp = file:read("*a")
    tmp = string.gsub(tmp,"404 Not Found", err .. " " .. desc)
    http_print(tmp)
    file:close()
  else
    http_print("<h1>" .. err .. " " .. desc .. "</h1>")
  end
end

local hex_to_char = function(x)
   return string.char(tonumber(x,16))
end

-- Robustes Parsen des application/x-www-form-urlencoded POST Bodies
local function parse_post_body()
    local params = {}
    local len = tonumber(os.getenv("CONTENT_LENGTH")) or 0
    if len > 0 then
        local body = io.read(len) or ""
        for pair in string.gmatch(body, "[^&]+") do
            local k, v = string.match(pair, "([^=]+)=(.*)")
            if k and v then
                v = string.gsub(v, "+", " ")
                v = string.gsub(v, "%%(%x%x)", hex_to_char)
                params[k] = v
            end
        end
    end
    return params
end

local userver = "download.digital-devices.de/download/linux"
local beta_userver = "download.digital-devices.de/download/linux/beta"
local data = nil
local delimages = false

-- ====================================================================
-- INTERACTION BLOCK: AJAX-Aufrufe von der neuen updateserver.html
-- ====================================================================

-- 1. GET-ZWEIG: Liest den Zustand für die Benutzeroberfläche aus
if method == "GET" and query:match("getserver=1") then
    http_print(proto .. " 200 OK")
    http_print("Content-Type: application/json; charset=UTF-8")
    http_print()
    
    local file = io.open(server_file, "r")
    if file then
        local tmp = file:read("*l") or ""
        file:close()
        tmp = tmp:gsub("%s+", "")
        -- Wenn ein echter Custom Server aktiv ist (weder Standard noch Beta)
        if tmp ~= "" and tmp ~= beta_userver and tmp ~= userver then
            http_print(string.format('{"type": "custom", "ip": "%s"}', tmp))
        else
            http_print(string.format('{"type": "official", "ip": "%s"}', tmp))
        end
    else
        -- Keine aktive Konfiguration, prüfen wir das Backup (.bak)
        local bak_file = io.open(server_bak, "r")
        if bak_file then
            local tmp = bak_file:read("*l") or ""
            bak_file:close()
            http_print(string.format('{"type": "official", "ip": "%s"}', tmp:gsub("%s+", "")))
        else
            http_print('{"type": "official", "ip": ""}')
        end
    end
    -- Beendet die Weboberflächen-Abfrage sofort, um das originale System-Fallback nicht zu stören
    os.exit()
end

-- 2. POST-ZWEIG: Verarbeitet das Umschalten und Sichern der reinen IP
if method == "POST" then
    local params = parse_post_body()
    if params.action == "saveserver" then
        if params.type == "official" then
            -- Konvention: Offiziell gewählt -> Lokalen Server zu .bak umbenennen
            local file = io.open(server_file, "r")
            if file then
                local current = file:read("*l") or ""
                file:close()
                if current ~= "" and current ~= beta_userver and current ~= userver then
                    os.remove(server_bak)
                    os.rename(server_file, server_bak)
                else
                    os.remove(server_file)
                end
            end
            delimages = true
        elseif params.type == "custom" and params.ip and params.ip ~= "" then
            -- Custom gewählt: Whitespaces entfernen, IP-Format erzwingen ohne http://
            local clean_ip = params.ip:gsub("%s+", ""):gsub("^https?://", "")
            
            -- Für die Luasocket-Validierung temporär ein Protokoll anfügen, damit url.parse funktioniert
            local test_url = "http://" .. clean_ip
            local valid = false
            local path = url.parse(test_url)
            local host_to_check = path.host or clean_ip
            
            -- Strikte Validierung der privaten Subnetze (10.x, 172.16-31.x, 192.168.x)
            local ip = host_to_check
            if not host_to_check:match("^(%d+)%.(%d+)%.(%d+)%.(%d+)$") then
                ip = socket.dns.toip(host_to_check) or host_to_check
            end
            
            local p1, p2 = ip:match("^(%d+)%.(%d+)%.%d+%.%d+$")
            if p1 and p2 then
                p1, p2 = tonumber(p1), tonumber(p2)
                valid = (p1 == 10) or ((p1 == 172) and (p2 >= 16) and (p2 <= 31)) or ((p1 == 192) and (p2 == 168))
            end
            
            if valid then
                os.remove(server_file)
                local file = io.open(server_file, "w")
                if file then
                    -- Schreibt NUR die reine IP und unterdrückt den Zeilenumbruch (\n)
                    file:write(clean_ip)
                    file:close()
                    os.remove(server_bak) -- Aktives Überschreiben löscht das Backup
                    delimages = true
                end
            else
                http_print(proto .. " 400 Bad Request")
                http_print("Content-Type: text/plain")
                http_print()
                http_print("Fehler: Ungueltige oder nicht-lokale IP/URL.")
                return
            end
        end
        
        if delimages then
            os.execute("rm -f /config/octonet.*.img")
            os.execute("rm -f /config/octonet.*.sha")
        end
        
        http_print(proto .. " 200 OK")
        http_print("Content-Type: text/plain")
        http_print()
        http_print("OK")
        return
    end
end

-- ====================================================================
-- ORIGINAL COMPATIBILITY BLOCK: Altes Verhalten für Online-Updates
-- ====================================================================

if query == "set=beta" then
  local file = io.open(server_file, "w")
  if file then
    file:write(beta_userver .. "\n")
    file:close()
    delimages = true
  end
elseif query == "set=std" then
   local file = io.open(server_file, "r")
   if file then
     file:close()
     os.remove(server_file)
     delimages = true
   end
elseif query:sub(1,4) == "set=" then
    userver = query:sub(5)
    if userver ~= "" then
      userver = userver:gsub("%%(%x%x)", hex_to_char)
      local valid = false
      
      local parse_url = userver
      if not parse_url:match("^http") then parse_url = "http://" .. parse_url end
      
      local path = url.parse(parse_url)
      local host_to_check = path.host or userver
      
      local ip = host_to_check
      if not host_to_check:match("^(%d+)%.(%d+)%.%d+%.%d+$") then
          ip = socket.dns.toip(host_to_check) or host_to_check
      end
      
      local p1, p2 = ip:match("^(%d+)%.(%d+)%.%d+%.%d+$")
      if p1 and p2 then
          p1 = tonumber(p1)
          p2 = tonumber(p2)
          valid = (p1 == 10) or ((p1 == 172) and (p2 >= 16) and (p2 <= 31)) or ((p1 == 192) and (p2 == 168))          
      end
      if valid then
         local file = io.open(server_file, "w")
         if file then
            file:write(userver .. "\n")
            file:close()
            delimages = true
         end
      else
         SendError("400 Bad Request", "Invalid or not local: " .. userver)
         return
      end
    else
      os.remove(server_file)
      delimages = true
    end
else
   data = "{ \"UpdateServer\":\""
   local file = io.open(server_file, "r")
   if file then
      local tmp = file:read("*l")
      file:close()
      if tmp ~= beta_userver then
         data = data .. tmp
      end      
   end
   data = data .. "\" }"   
end

if delimages then
    os.execute("rm -f /config/octonet.*.img")
    os.execute("rm -f /config/octonet.*.sha")
end

if data then
   http_print(proto .. " 200 OK")
   http_print("Pragma: no-cache")
   http_print("Cache-Control: no-cache")
   http_print("Content-Type: application/json; charset=UTF-8")
   http_print(string.format("Content-Length: %d", #data))
   http_print()
   http_print(data)
else
   http_print(proto .. " 303 See Other")
   http_print("Location: http://" .. host .. "/update.html")
   http_print("")
end

