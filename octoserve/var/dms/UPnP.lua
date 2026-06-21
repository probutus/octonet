#!/usr/bin/lua

UPnP = {}

local socket = require("socket")
local mime = require("mime") -- KORREKTUR: Fest importiert für die Event-Kodierung!

local DebugFlag = false
local Server = "Linux/3.9 DLNADOC/1.50 UPnP/1.0 OctopusNet-DMS/1.0"

if DisableDLNA then
  Server = "Linux/3.9 UPnP/1.0 OctopusNet-DMS/1.0"
end

function UPnP:SetDebug(f)
  DebugFlag = f
end

UPnP.Server = Server

function UPnP:ParseHTTPHeader(header)
  local linenum = 0
  local method,path,proto
  local attributes = {}
  
  for line in string.gmatch(header,"(.-)\r\n") do
    if not line then break end
    if DebugFlag then print(string.format("%2d:%s",linenum,line)) end
    if linenum == 0 then 
      method,path,proto = string.match(line,"(.+)%s+(.+)%s+(.+)")
    else
      local n,v = string.match(line,"([%a%-]+)%s*%:%s*(.*)")
      if n and v then
        attributes[string.upper(n)] = v
      end
    end
    
    linenum = linenum + 1
  end  
  return method,path,proto,attributes
end

function UPnP:ReadHTTPHeader(client)
  local linenum = 0
  local line, err = client:receive()
  
  if err then
    if DebugFlag then print("HTTPHeader Error "..err) end
    return 
  end

  if DebugFlag then print(string.format("%2d:%s",linenum,line)) end
  local method,path,proto = string.match(line,"(.+)%s+(.+)%s+(.+)")
  local attributes = {}

  while true do
    local line, err = client:receive()
    if err then 
      if DebugFlag then print("HTTPHeader Error "..err.." HTTP Line: "..tostring(linenum)) end
      return 
    end
    linenum = linenum + 1
    if DebugFlag then print(string.format("%2d:%s",linenum,line)) end
    if line == "" then break end
    
    if linenum == 30 then
      if DebugFlag then print("HTTPHeader Error "..tostring(linenum)) end
      return 
    end
    
    local n,v = string.match(line,"([%a%-]+)%s*%:%s*(.*)")
    if n and v then
      attributes[string.upper(n)] = v
    end
  end
  
  if attributes["HOST"] then
    local Host,Port = string.match(attributes["HOST"],"(.+)%:(%d+)")
    attributes["host"] = Host
    attributes["port"] = Port
  end

  return method,path,proto,attributes
end
function UPnP:ReadHTTPBody(client,clen)
  local Body = ""
  if DebugFlag and clen then print(string.format("---- Length = %d",clen)) end

  Body, err = client:receive(clen)
  if err then 
    if DebugFlag then print("HTTPBody Error "..err) end
    return 
  end  
  return Body
end

function UPnP:ParseInvocation(soap,Service)
end

function UPnP:CreateResponse(Service,Action,Args)
  local soap = '<?xml version="1.0" encoding="utf-8"?>'..'\r\n'
            -- KORREKTUR: Bereinigter XML-Namensraum-String für reibungsloses SOAP-Parsing der Clients
            .. "<s:Envelope xmlns:s=\"http://xmlsoap.org\" s:encodingStyle=\"http://xmlsoap.org\">"
            .. "<s:Body><u:"..Action.."Response "..Service..">"
  for _,a in ipairs(Args) do
    soap = soap .. "<"..a.n..">"..a.v.."</"..a.n..">"
  end
  soap = soap .. "</u:"..Action.."Response></s:Body></s:Envelope>"..'\r\n'
  return soap
end

function UPnP:SendResponse(client,Content)
  local r = "HTTP/1.1 200 OK\r\n"
          .. "Content-Type: text/xml; charset=\"utf-8\"\r\n"
          .. "Connection: close\r\n"
          .. "Content-Length: "..string.format("%d",#Content).."\r\n"
          .. "Server: "..Server.."\r\n"
          .. "Date: "..os.date("!%a, %d %b %Y %H:%M:%S GMT").."\r\n"
          .. "EXT:\r\n"
          .. "\r\n"
          .. Content  
  client:send(r)  
end

function UPnP:GetRequestParam(Request,Param)
  return string.match(Request,"%<"..Param..".*%>%s*(.+)%s*%<%/"..Param.."%>")
end
local SoapErrorDescription = {}
SoapErrorDescription[402] = "Invalid Args"

function UPnP:SendSoapError(client,code)
  local soap = '<?xml version="1.0" encoding="utf-8"?>'
            .. "<s:Envelope xmlns:s=\"http://xmlsoap.org\" s:encodingStyle=\"http://xmlsoap.org\">"
            .. "<s:Body>"
            .. "<s:Fault>"
            .. "<s:faultcode>s:Client</s:faultcode>"
            .. "<s:faultstring>UPnPError</s:faultstring>"
            .. "<s:detail>"
            .. '<UPnPError xmlns="urn:schemas-upnp-org:control-1-0">'
            .. '<errorCode>'..code..'</errorCode>'
            .. '<errorDescription>'..tostring(SoapErrorDescription[code] or "Unknown Error")..'</errorDescription>'
            .. '</UPnPError>'
            .. "</s:detail>"
            .. "</s:fault>"
            .. "</s:Body>"
            .. "</s:Envelope>"

  local r = "HTTP/1.1 500 Internal Server Error\r\n"
          .. "Content-Type: text/xml; charset=\"utf-8\"\r\n"
          .. "Connection: close\r\n"
          .. "Content-Length: "..string.format("%d",#soap).."\r\n"
          .. "Server: "..Server.."\r\n"
          .. "Date: "..os.date("!%a, %d %b %Y %H:%M:%S GMT").."\r\n"
          .. "EXT:\r\n"
          .. "\r\n"
          .. soap  
  client:send(r)  
end

function UPnP:SendHTTPError(client,code)
  local r = "HTTP/1.1 " ..code.."\r\n"
          .. "Content-Type: text/html\r\n"
          .. "Connection: Close\r\n"
          .. "Server: "..UPnP.Server.."\r\n"
          .. "Date: "..os.date("!%a, %d %b %Y %H:%M:%S GMT").."\r\n"
          .. "\r\n"
          .. "<html><head><title>Error "..code.."</title></head><body><h1>Error "..code.."</h1></body></html>\r\n"
  client:send(r)
end

function UPnP:SendEvent(path,uuid,seq,values)
  local xml = ""
  for _,v in ipairs(values) do
    xml = xml .. "<"..v.n..">"..v.v.."</"..v.n..">\r\n"
  end
  if xml == "" then xml="nil" end
  
  -- Hier greift nun die in Teil 1 importierte mime-Bibliothek fehlerfrei
  local b64 = mime.b64(xml)
  os.execute('lua SendEvent.lua "'..path..'" "'..uuid..'" "'..seq..'" "'..b64..'"&')
end

function UPnP:SystemParameters(template)
  local ifconfig = io.popen("ifconfig eth0")
  assert(ifconfig)
  local eth0 = ifconfig:read("*a")
  ifconfig:close()
  
  -- Akzeptiert flexibel sowohl Doppelpunkt als auch Leerzeichen nach "inet addr"
  local myip = string.match(eth0,"inet addr%s*%:?%s*(%d+%.%d+%.%d+%.%d+)")
  local hwaddr = string.match(eth0,"HWaddr%s+(%x+%:%x+%:%x+%:%x+%:%x+%:%x+)")
  
  if not hwaddr then
    hwaddr = string.match(eth0,"ether%s+(%x+%:%x+%:%x+%:%x+%:%x+%:%x+)")
  end
  
  local guidend = string.gsub(hwaddr or "00:00:00:00:00:00","%:","")
  local sernbr = tonumber(string.sub(guidend,-6),16) or 0
  local uuid = string.lower(string.gsub(template,"000000000000",guidend))
  
  return uuid,sernbr,myip
end

-- Gewährleistet globale Sichtbarkeit für dms.lua und Submodule
_G.UPnP = UPnP
return UPnP

