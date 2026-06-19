#!/usr/bin/env lua

-- Verzeichnis für die Konfiguration definieren
local config_dir = "/config/"

-- HTTP-Header vom Webserver (uWSGI/Lighttpd) auslesen
local fw_date = os.getenv("HTTP_X_FIRMWARE_DATE")
local fw_hash = os.getenv("HTTP_X_FIRMWARE_HASH")

-- Validierung: Wenn Header fehlen, Upload abbrechen
if not fw_date or not fw_hash or not fw_date:match("^%d%d%d%d%d%d%d%d$") or not fw_hash:match("^%x%x%x%x%x+$") then
    print("Status: 400 Bad Request")
    print("Content-Type: text/plain\n")
    print("Fehler: Ungueltige oder fehlende Firmware-Metadaten in den Headern.")
    return
end

-- Ziel-Dateipfade definieren
local img_filename = "octonet_" .. fw_date .. ".img"
local sha_filename = "octonet_" .. fw_date .. ".sha"
local target_img_path = config_dir .. img_filename
local target_sha_path = config_dir .. sha_filename

-- 1. SCHRITT: Erzeuge die .sha Datei direkt aus dem Header-Inhalt
local sha_file, err = io.open(target_sha_path, "w")
if not sha_file then
    print("Status: 500 Internal Server Error")
    print("Content-Type: text/plain\n")
    print("Fehler beim Schreiben der SHA-Datei: " .. tostring(err))
    return
end
-- Format für sha256sum: "HASH  DATEINAME"
sha_file:write(fw_hash .. "  " .. img_filename .. "\n")
sha_file:close()

-- 2. SCHRITT: Datenstrom (Multipart/Form-Data) ressourcenschonend einlesen
-- Hinweis: In einer echten CGI/Lua-Umgebung liest man io.stdin. 
-- Hier wird der Rohdatenstrom direkt in die Ziel-Bilddatei geschrieben.
local img_file, img_err = io.open(target_img_path, "wb")
if not img_file then
    print("Status: 500 Internal Server Error")
    print("Content-Type: text/plain\n")
    print("Fehler beim Erstellen der Image-Datei: " .. tostring(img_err))
    return
end

-- Blockweises Lesen von stdin, um den RAM-Verbrauch minimal zu halten
local chunk_size = 4096
while true do
    local chunk = io.read(chunk_size)
    if not chunk or #chunk == 0 then break end
    img_file:write(chunk)
end
img_file:close()

-- 3. SCHRITT: Integritaetspruefung via System-Befehl auf dem Geraet
-- Wechselt in den Ordner und prueft die soeben erzeugten Dateien
local check_cmd = "cd " .. config_dir .. " && sha256sum -c " .. sha_filename .. " > /dev/null 2>&1"
local success = os.execute(check_cmd)

if success then
    -- Erfolgreiche Antwort an den Browser senden
    print("Status: 200 OK")
    print("Content-Type: text/plain\n")
    print("Erfolg: " .. img_filename .. " und " .. sha_filename .. " wurden erfolgreich verifiziert und in " .. config_dir .. " abgelegt.")
else
    -- Bei Fehlschlag (z.B. Uebertragungsfehler) kaputte Datei loeschen
    os.remove(target_img_path)
    os.remove(target_sha_path)
    
    print("Status: 422 Unprocessable Entity")
    print("Content-Type: text/plain\n")
    print("Fehler: Die SHA256-Pruefsumme der uebertragenen Datei stimmt nicht ueberein! Dateien wurden verworfen.")
end

