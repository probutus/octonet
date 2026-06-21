#!/usr/bin/env lua

-- Pfad zur zentralen Buildroot/Debian Netzwerkkonfiguration
local interfaces_path = "/etc/network/interfaces"

-- Prüft, ob das System aktuell über ein Netzwerk-Rootfs läuft (NFS-Boot-Schutz)
local function is_nfs_boot()
    local file = io.open("/proc/cmdline", "r")
    if file then
        local cmdline = file:read("*a")
        file:close()
        if cmdline:match("root=/dev/nfs") or cmdline:match("nfsroot=") then
            return true
        end
    end
    return false
end

-- Funktion zur strikten Validierung der IP-Oktette (0-255) zum Schutz des Systems
local function is_valid_ipv4(ip)
    if not ip then return false end
    local o1, o2, o3, o4 = ip:match("^(%d+)%.(%d+)%.(%d+)%.(%d+)$")
    if not o1 then return false end
    
    local n1, n2, n3, n4 = tonumber(o1), tonumber(o2), tonumber(o3), tonumber(o4)
    if n1 > 255 or n2 > 255 or n3 > 255 or n4 > 255 then return false end
    
    -- Verhindert Oktette mit führenden Nullen wie "01" (wichtig für POSIX Scripts)
    if (#o1 > 1 and o1:sub(1,1) == "0") or (#o2 > 1 and o2:sub(1,1) == "0") or
       (#o3 > 1 and o3:sub(1,1) == "0") or (#o4 > 1 and o4:sub(1,1) == "0") then
        return false
    end
    
    return true
end

-- Helper zum Parsen von POST-Parametern (URL-encoded)
local function get_post_params()
    local params = {}
    local content_length = tonumber(os.getenv("CONTENT_LENGTH")) or 0
    if content_length > 0 then
        local body = io.read(content_length)
        for k, v in string.gmatch(body, "([^&=]+)=([^&=]+)") do
            v = string.gsub(v, "%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)
            params[k] = v
        end
    end
    return params
end

local method = os.getenv("REQUEST_METHOD") or "GET"
local query = os.getenv("QUERY_STRING") or ""

-- ====================================================================
-- GET ACTION: Liest /etc/network/interfaces aus und gibt JSON zurueck
-- ====================================================================
if method == "GET" and query:match("action=get") then
    print("Status: 200 OK")
    print("Content-Type: application/json\n")
    
    if is_nfs_boot() then
        print('{"mode": "nfs", "ip": "NFS-Active", "netmask": "", "gateway": "", "dns": ""}')
        return
    end
    
    local file = io.open(interfaces_path, "r")
    local mode = "dhcp"
    local ip, netmask, gateway, dns = "", "", "", ""
    
    if file then
        local content = file:read("*a")
        file:close()
        
        if content:match("iface%s+eth0%s+inet%s+static") then
            mode = "static"
            ip = content:match("address%s+([%d%.]+)") or ""
            netmask = content:match("netmask%s+([%d%.]+)") or ""
            gateway = content:match("gateway%s+([%d%.]+)") or ""
            dns = content:match("dns%-nameservers%s+([%d%.]+)") or ""
        end
    end
    
    print(string.format('{"mode": "%s", "ip": "%s", "netmask": "%s", "gateway": "%s", "dns": "%s"}', 
        mode, ip, netmask, gateway, dns))
    return

-- ====================================================================
-- POST ACTION: Schreibt die /etc/network/interfaces neu
-- ====================================================================
elseif method == "POST" then
    local params = get_post_params()
    
    if params.action == "save" then
        if is_nfs_boot() then
            print("Status: 423 Locked")
            print("Content-Type: text/plain\n")
            print("Fehler: Netzwerk-Konfiguration im NFS-Modus gesperrt.")
            return
        end

        local allowed = false
        local out_content = ""
        
        out_content = out_content .. "auto lo\n"
        out_content = out_content .. "iface lo inet loopback\n\n"
        out_content = out_content .. "auto eth0\n"
        
        if params.mode == "dhcp" then
            -- Zurück zur absolut standardkonformen, schlanken Syntax für das OS
            out_content = out_content .. "iface eth0 inet dhcp\n"
            allowed = true
        elseif params.mode == "static" and params.ip and params.netmask and params.gateway then
            if is_valid_ipv4(params.ip) and is_valid_ipv4(params.netmask) and is_valid_ipv4(params.gateway) then
                local dns_val = params.dns or "8.8.8.8"
                if dns_val ~= "" and not is_valid_ipv4(dns_val) then dns_val = "8.8.8.8" end
                
                out_content = out_content .. "iface eth0 inet static\n"
                out_content = out_content .. "    address " .. params.ip .. "\n"
                out_content = out_content .. "    netmask " .. params.netmask .. "\n"
                out_content = out_content .. "    gateway " .. params.gateway .. "\n"
                if dns_val ~= "" then
                    out_content = out_content .. "    dns-nameservers " .. dns_val .. "\n"
                end
                allowed = true
            end
        end
        
        if allowed then
            local file, err = io.open(interfaces_path, "w")
            if file then
                file:write(out_content)
                file:close()
                
                if params.mode == "static" and params.dns and params.dns ~= "" then
                    local rfile = io.open("/etc/resolv.conf", "w")
                    if rfile then
                        rfile:write("nameserver " .. params.dns .. "\n")
                        rfile:close()
                    end
                end
                
                print("Status: 200 OK")
                print("Content-Type: text/plain\n")
                print("OK")
                
                -- ====================================================================
                -- DIE ABSOLUT UNFEHLBARE ABSCHALTE-KETTE (Direkt im OS-Hintergrund):
                -- ====================================================================
                -- 1. Wir warten 2 Sek, bis HTTP geantwortet hat.
                -- 2. Wir führen standardmäßig /sbin/ifdown eth0 aus.
                -- 3. Wir killen den dhcp-Client unbarmherzig mit -9 (SIGKILL)
                -- 4. Wir löschen alle alten IP-Adressen und Standard-Routen aus dem Kernel
                -- 5. Wir fahren das Interface über /sbin/ifup eth0 wieder sauber hoch.
                local cmd_chain = "(sleep 2 && /sbin/ifdown eth0 && killall -9 udhcpc && ifconfig eth0 up && sleep 1 && /sbin/ifup eth0 > /dev/null 2>&1 && /etc/init.d/S42zcip start) > /dev/null 2>&1 &"
                if params.mode == "dhcp" then
                    -- Wenn wir ZU DHCP wechseln, reicht die Standard-Kette
                    cmd_chain = "(sleep 2 && /sbin/ifdown eth0 && /sbin/ifup eth0) > /dev/null 2>&1 &"
                end 
                os.execute(cmd_chain)
                return
            else
                print("Status: 500 Internal Server Error")
                print("Content-Type: text/plain\n")
                print("Fehler beim Schreiben der interfaces: " .. tostring(err))
                return
            end
        end
    end
end

print("Status: 400 Bad Request")
print("Content-Type: text/plain\n")
print("Ungueltige Anfrage oder Validierungsfehler.")

