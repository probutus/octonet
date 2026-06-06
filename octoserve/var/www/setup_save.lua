#!/usr/bin/lua

-- 1. POST-Daten (Formular) einlesen
local content_length = tonumber(os.getenv("CONTENT_LENGTH")) or 0
local post_data = ""
if content_length > 0 then
    post_data = io.read(content_length)
end

-- Hilfsfunktion zum Dekodieren der Parameter
function get_param(data, key)
    local val = data:match(key .. "=([^&]*)")
    if val then
        -- Einfaches URL-Decode für Sonderzeichen im Passwort
        val = val:gsub("+", " "):gsub("%%(%x%x)", function(h) return string.char(tonumber(h,16)) end)
    end
    return val
end

local pwd1 = get_param(post_data, "pwd1")
local pwd2 = get_param(post_data, "pwd2")

-- HTML-Ausgabe vorbereiten
print("Content-type: text/html\n")

-- Prüfen, ob die Passwortdatei bereits existiert (Sicherheitsschutz vor Überschreiben!)
local f = io.open("/etc/lighttpd/.htdigest", "r")
if f then
    f:close()
    print("<h2>Fehler: Das System ist bereits konfiguriert!</h2>")
    os.exit()
end

if not pwd1 or pwd1 == "" or pwd1 ~= pwd2 then
    print("<h2>Fehler: Passwörter stimmen nicht überein! Go back.</h2>")
    os.exit()
end

-- 2. Digest-Hash generieren
-- Format für htdigest ist: md5(username : realm : password)
local user = "admin"
local realm = "Octonet Protected Area"
local raw_string = user .. ":" .. realm .. ":" .. pwd1

-- Wir nutzen das Linux-Kommando 'md5sum', da wir kein Krypto-Modul in Lua zwingend laden wollen
local handle = io.popen("echo -n '" .. raw_string .. "' | md5sum")
local md5_res = handle:read("*a")
handle:close()
local hash = md5_res:match("(%x+)")

-- 3. In htdigest-Datei schreiben
local out = io.open("/etc/etc/lighttpd/.htdigest", "w") -- Pfad ggf. auf /etc/lighttpd/.htdigest korrigieren
-- Falls das Verzeichnis fehlt:
os.execute("mkdir -p /etc/lighttpd")
out = io.open("/etc/lighttpd/.htdigest", "w")
out:write(user .. ":" .. realm .. ":" .. hash .. "\n")
out:close()

-- Verhindern, dass andere Prozesse die Datei lesen
os.execute("chmod 600 /etc/etc/lighttpd/.htdigest") 

-- 4. Erfolg melden und Webserver neu starten, damit die Sperre aktiv wird
print("<h2>Passwort erfolgreich gesetzt!</h2>")
print("<p>Das System startet das Webinterface jetzt neu. Sie werden gleich zum Login weitergeleitet...</p>")
print("<script>setTimeout(function(){ window.location.href = '/'; }, 3000);</script>")

-- Lighttpd im Hintergrund sanft neu laden, um die Authentifizierung scharfzuschalten
os.execute("sleep 2 && /etc/init.d/S50lighttpd restart &")

