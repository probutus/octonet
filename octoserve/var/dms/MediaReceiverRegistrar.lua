MediaReceiverRegistrar = {}

-- KORREKTUR: Lokaler Zugriff auf das UPnP-Objekt, falls es global registriert ist
local upnp_framework = _G.UPnP or UPnP or {}

function MediaReceiverRegistrar:Description()
  -- KORREKTUR: Variable lokalisiert
  local t = ""
  local f = io.open("MediaReceiverRegistrar.xml","r")
  if not f then os.exit() end
  while true do
    local line = f:read()
    if not line then break end
    t = t .. line .. "\r\n"  
  end
  f:close()
  return t
end

local function SendResult(client,Action,Result)
  local Args = { { n = "Result", v = Result } }
  -- KORREKTUR: upnp_framework statt UPnP genutzt
  upnp_framework:SendResponse(client,upnp_framework:CreateResponse('xmlns:u="urn:microsoft-com:service:X_MS_MediaReceiverRegistrar:1"',Action,Args))
end

function MediaReceiverRegistrar:Invoke(client,Attributes,Request)
  local Action = string.match(Attributes["SOAPACTION"],".+%#(%a+)")
  print("MediaReceiverRegistrar",Action)
  if Action == "IsAuthorized" then 
    SendResult(client,Action,"1") 
  elseif Action == "IsValidated" then 
    SendResult(client,Action,"1") 
  else
    -- KORREKTUR: upnp_framework statt UPnP genutzt
    upnp_framework:SendSoapError(client,401)
  end
  return
end

function MediaReceiverRegistrar:Subscribe(client,callback,timeout)
  local server_string = upnp_framework.Server or "Linux/3.9 UPnP/1.0 OctopusNet-DMS/1.0"
  local r = "HTTP/1.1 200 OK\r\n"
          .. 'Content-Type: text/xml; charset="utf-8"\r\n'
          .. "Server: "..server_string.."\r\n"
          .. "SID: uuid:50c95802-e839-4b96-b7ae-779d989e1399\r\n"
          .. "Timeout: Second-1800\r\n"
          .. "Content-Length: 0\r\n"
          .. "Connection: close\r\n"
          .. "EXT:\r\n"
          .. "\r\n"
  client:send(r)  
  
  local ipaddr,port = client:getpeername()  
  -- KORREKTUR: upnp_framework statt UPnP genutzt
  upnp_framework:SendEvent(callback,"50c95802-e839-4b96-b7ae-779d989e1399",0,{} )
end

function MediaReceiverRegistrar:Renew(client,sid,timeout)
  local server_string = upnp_framework.Server or "Linux/3.9 UPnP/1.0 OctopusNet-DMS/1.0"
  local r = "HTTP/1.1 200 OK\r\n"
          .. 'Content-Type: text/xml; charset="utf-8"\r\n'
          .. "Server: "..server_string.."\r\n"
          .. "SID: uuid:50c95802-e839-4b96-b7ae-779d989e1399\r\n"
          .. "Timeout: Second-1800\r\n"
          .. "Content-Length: 0\r\n"
          .. "Connection: close\r\n"
          .. "EXT:\r\n"
          .. "\r\n"
  client:send(r)  
end

function MediaReceiverRegistrar:Unsubscribe(client,sid)
  local server_string = upnp_framework.Server or "Linux/3.9 UPnP/1.0 OctopusNet-DMS/1.0"
  local r = "HTTP/1.1 200 OK\r\n"
          .. "Server: "..server_string.."\r\n"
          .. "Connection: close\r\n"
          .. "\r\n"
  client:send(r)  
end

return MediaReceiverRegistrar

