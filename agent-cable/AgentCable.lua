-- Agent Cable para REAPER: ventana de chat que habla con Claude Code (suscripcion, sin API paga)
-- y actua sobre REAPER mediante la cola run/ (cada pedido de Claude = un paso de deshacer).
local R = reaper
local SEP = package.config:sub(1, 1)
local BASE = ({R.get_action_context()})[2]:match("^(.*)[/\\]") or ""
local RUN, WORK = BASE .. "/run", BASE .. "/work"
R.RecursiveCreateDirectory(RUN, 0); R.RecursiveCreateDirectory(WORK, 0)

if not R.ImGui_GetBuiltinPath then
  R.MB("Agent Cable necesita la extension ReaImGui.\nInstalala desde ReaPack (ReaTeam Extensions > ReaImGui) y reinicia REAPER.", "Agent Cable", 0)
  return
end
-- shim minimo: las constantes de ReaImGui son funciones reaper.ImGui_Grupo_Nombre(); el resto son funciones
local ImGui = setmetatable({}, {__index = function(t, k)
  local f = R["ImGui_" .. k]
  local v = f
  local pre = k:match("^(%a+)_")
  local es_fn = pre == "DrawList" or pre == "ListClipper" or pre == "Viewport" or pre == "DrawListSplitter" or pre == "TextFilter" or pre == "Function" or pre == "Font"
  if f and pre and not es_fn then v = f() end
  rawset(t, k, v); return v
end})

---------------------------------------------------------------- JSON (lector minimo)
local function jdecode(s)
  local pos = 1
  local function ws() pos = s:find("[^ \t\r\n]", pos) or #s + 1 end
  local val
  local function str()
    local out, i = {}, pos + 1
    while true do
      local c = s:sub(i, i)
      if c == '"' then pos = i + 1; return table.concat(out)
      elseif c == "\\" then
        local n = s:sub(i + 1, i + 1)
        if n == "u" then
          local cp = tonumber(s:sub(i + 2, i + 5), 16); i = i + 6
          if cp >= 0xD800 and cp < 0xDC00 and s:sub(i, i + 1) == "\\u" then
            local lo = tonumber(s:sub(i + 2, i + 5), 16); cp = 0x10000 + (cp - 0xD800) * 0x400 + (lo - 0xDC00); i = i + 6
          end
          out[#out + 1] = utf8.char(cp)
        else
          out[#out + 1] = ({n = "\n", t = "\t", r = "\r", b = "\b", f = "\f"})[n] or n; i = i + 2
        end
      elseif c == "" then error("json: string sin cerrar")
      else out[#out + 1] = c; i = i + 1 end
    end
  end
  function val()
    ws(); local c = s:sub(pos, pos)
    if c == "{" then
      local t = {}; pos = pos + 1; ws()
      if s:sub(pos, pos) == "}" then pos = pos + 1; return t end
      while true do
        ws(); local k = str(); ws(); pos = pos + 1; t[k] = val(); ws()
        local d = s:sub(pos, pos); pos = pos + 1
        if d == "}" then return t end
      end
    elseif c == "[" then
      local t = {}; pos = pos + 1; ws()
      if s:sub(pos, pos) == "]" then pos = pos + 1; return t end
      while true do
        t[#t + 1] = val(); ws()
        local d = s:sub(pos, pos); pos = pos + 1
        if d == "]" then return t end
      end
    elseif c == '"' then return str()
    elseif s:sub(pos, pos + 3) == "true" then pos = pos + 4; return true
    elseif s:sub(pos, pos + 4) == "false" then pos = pos + 5; return false
    elseif s:sub(pos, pos + 3) == "null" then pos = pos + 4; return nil
    else
      local num = s:match("^-?%d+%.?%d*[eE]?[+-]?%d*", pos); pos = pos + #num; return tonumber(num)
    end
  end
  return val()
end

---------------------------------------------------------------- estado
local ctx = ImGui.CreateContext("Agent Cable")
local fuente
do
  local ok, f = pcall(function() local f = ImGui.CreateFont("sans-serif"); ImGui.Attach(ctx, f); return f end)
  if ok then fuente = f end
end
local msgs = {}            -- {rol="yo"|"claude"|"paso"|"sis", txt=...}
local entrada, session_id = "", nil
local corriendo, turno, t0 = false, 0, 0
local outpath, leidos, resto = nil, 0, ""
local scroll_abajo, foco = true, true
local rol_col = {yo = 0x7FB3FFFF, claude = 0xEDEDEDFF, paso = 0x9A9A9AFF, sis = 0xE8B04AFF}

local ultimo_pedido = ""
local function say(rol, txt) msgs[#msgs + 1] = {rol = rol, txt = txt}; scroll_abajo = true end
local function wfile(p, s) local f = io.open(p, "wb"); if f then f:write(s); f:close() end end
local function rfile(p) local f = io.open(p, "rb"); if not f then return nil end; local s = f:read("a"); f:close(); return s end

---------------------------------------------------------------- cola: Claude -> REAPER
local function jstr(v)
  if type(v) == "table" then
    local p = {}
    for k, x in pairs(v) do p[#p + 1] = string.format("%q:%s", tostring(k), jstr(x)) end
    return "{" .. table.concat(p, ",") .. "}"
  elseif type(v) == "string" then
    return '"' .. v:gsub('[%c"\\]', function(c) return string.format("\\u%04x", c:byte()) end) .. '"'
  else return tostring(v) end
end

-- con REAPER en segundo plano los audios pueden quedar offline (preferencia "Set media items offline when application is not active"):
-- antes de cada pedido se ponen online, conservando la seleccion de items del usuario
local function poner_online()
  local sel = {}
  for i = 0, R.CountMediaItems(0) - 1 do
    local it = R.GetMediaItem(0, i); if R.IsMediaItemSelected(it) then sel[#sel + 1] = it end
  end
  R.SelectAllMediaItems(0, true); R.Main_OnCommand(40101, 0); R.SelectAllMediaItems(0, false)
  for _, it in ipairs(sel) do R.SetMediaItemSelected(it, true) end
end

local function procesar_cola()
  local i = 0
  while true do
    local f = R.EnumerateFiles(RUN, i); i = i + 1
    if not f then break end
    local id = f:match("^(.+)%.lua$")
    if id then
      local src = rfile(RUN .. "/" .. f)
      os.remove(RUN .. "/" .. f)
      if src and (src:find("os.remove", 1, true) or src:find("os.rename", 1, true) or src:find("os.execute", 1, true) or src:find("io.popen", 1, true) or src:find("ExecProcess", 1, true)) then
        wfile(RUN .. "/" .. id .. ".tmp", jstr({ok = false, out = "BLOQUEADO: borrar, renombrar o ejecutar comandos desde Lua no esta permitido (los originales no se tocan)."}))
        os.rename(RUN .. "/" .. id .. ".tmp", RUN .. "/" .. id .. ".res")
        say("sis", "Bloqueé una operación de archivos.")
      elseif src and (src:find("42230", 1, true) or src:find("RENDER_", 1, true) or src:find("Main_OnCommand%(%s*4182[0-9]") or src:find("Main_OnCommand%(%s*4101[5-9]"))
         and not ultimo_pedido:lower():find("stem") and not ultimo_pedido:lower():find("export") and not ultimo_pedido:lower():find("render") and not ultimo_pedido:lower():find("bounce") then
        wfile(RUN .. "/" .. id .. ".tmp", jstr({ok = false, out = "BLOQUEADO: el usuario no pidio exportar ni renderizar. No renderices (ni para sondear). Hace el cambio con automatizacion/parametros y mostra el resultado sin exportar."}))
        os.rename(RUN .. "/" .. id .. ".tmp", RUN .. "/" .. id .. ".res")
        say("sis", "Bloqueé un render que no pediste.")
      elseif src then
        local salida = {}
        local env = setmetatable({reaper = R, out = function(...)
          local t = {}; for j = 1, select("#", ...) do t[j] = tostring((select(j, ...))) end
          salida[#salida + 1] = table.concat(t, " ")
        end}, {__index = _G})
        env.print = env.out
        local okl, lib = pcall(function() return dofile(BASE .. "/work/cable_lib.lua") end)
        if okl then env.lib = lib else env.lib = nil; salida[#salida + 1] = "(lib no cargo: " .. tostring(lib) .. ")" end
        local etiqueta = src:match("^%-%-%s*cable:%s*([^\n\r]+)") or "pedido"
        poner_online()
        R.Undo_BeginBlock2(0); R.PreventUIRefresh(1)
        local fn, err = load(src, "=cable", "t", env)
        local ok, ret = false, err
        if fn then ok, ret = pcall(fn) end
        R.PreventUIRefresh(-1); R.UpdateArrange(); R.TrackList_AdjustWindows(false)
        R.Undo_EndBlock2(0, "Agent Cable: " .. etiqueta, -1)
        if ret ~= nil then salida[#salida + 1] = tostring(ret) end
        wfile(RUN .. "/" .. id .. ".tmp", jstr({ok = ok, out = table.concat(salida, "\n")}))
        os.rename(RUN .. "/" .. id .. ".tmp", RUN .. "/" .. id .. ".res")
        if not ok then say("sis", "REAPER (error): " .. etiqueta) end
      end
    end
  end
end

---------------------------------------------------------------- Claude Code en segundo plano
---------------------------------------------------------------- sesion de Claude (login desde la ventana)
local auth, ultimo_chequeo, esperando_prueba = "?", 0, false
local function sh(args) R.ExecProcess(string.format('/bin/sh "%s/auth.sh" %s', BASE, args), 3000) end
local function chequear_auth() ultimo_chequeo = R.time_precise(); sh("status") end
local function conectar()   -- abre la Terminal con el inicio de sesion OFICIAL de Anthropic; esta ventana no toca ni guarda credenciales
  auth = "login"
  sh("login")
end
local function leer_auth()
  local t = rfile(BASE .. "/auth.txt")
  if t then
    os.remove(BASE .. "/auth.txt"); t = t:gsub("%s+", "")
    if t == "ok" then
      local venia = auth ~= "ok"
      auth = "ok"
      if venia and esperando_prueba then say("sis", "Conectado con Claude."); esperando_prueba = false; PRUEBA = true end
    elseif auth ~= "login" then auth = "no" end
  end
  if (auth == "login" or auth == "?") and R.time_precise() - ultimo_chequeo > 3 then chequear_auth() end
end

---------------------------------------------------------------- modelo y esfuerzo (elegibles, se recuerdan)
local MODELOS = {{"Opus 5.5", "claude-opus-5-5"}, {"Sonnet 5.5", "claude-sonnet-5-5"}, {"Haiku 5.5", "claude-haiku-5-5"}}
local ESFUERZOS = {{"bajo", "low"}, {"medio", "medium"}, {"alto", "high"}}
local m_i, e_i, modelo_real = 1, 2, nil   -- por defecto: Opus, esfuerzo medio
do
  local c = rfile(BASE .. "/config.txt")
  if c then
    local a, b = c:match("(%d)%s+(%d)")
    if a and MODELOS[tonumber(a)] and ESFUERZOS[tonumber(b)] then m_i, e_i = tonumber(a), tonumber(b) end
  end
end
local function guardar_cfg() wfile(BASE .. "/config.txt", m_i .. " " .. e_i) end

local function lanzar(pedido)
  turno = turno + 1
  local pf = BASE .. "/turno_" .. turno .. ".txt"
  outpath = BASE .. "/turno_" .. turno .. ".jsonl"
  wfile(pf, pedido); wfile(outpath, "")
  leidos, resto, corriendo, t0 = 0, "", true, R.time_precise()
  local cmd = string.format('/bin/bash "%s/lanzar.sh" "%s" "%s" "%s" "%s" "%s" "%s"', BASE, pf, outpath, WORK, session_id or "", MODELOS[m_i][2], ESFUERZOS[e_i][2])
  R.ExecProcess(cmd, 3000)
end

local function leer_salida()
  if not outpath then return end
  local f = io.open(outpath, "rb"); if not f then return end
  f:seek("set", leidos); local nuevo = f:read("a") or ""; f:close()
  if nuevo == "" then return end
  leidos = leidos + #nuevo
  local buf = resto .. nuevo
  local ult = buf:match(".*()\n")
  if not ult then resto = buf; return end
  resto = buf:sub(ult + 1)
  for linea in buf:sub(1, ult):gmatch("[^\n]+") do
    if linea:sub(1, 1) == "{" then
      local ok, ev = pcall(jdecode, linea)
      if ok and type(ev) == "table" then
        if ev.type == "system" and ev.subtype == "init" and ev.model then modelo_real = ev.model end
        if ev.type == "assistant" and ev.message and ev.message.content then
          for _, b in ipairs(ev.message.content) do
            if b.type == "text" and b.text and b.text ~= "" then say("claude", b.text) end
          end
        elseif ev.type == "result" then
          session_id = ev.session_id or session_id
          corriendo = false
          if ev.is_error then
            if tostring(ev.result):find("authenticate") or ev.api_error_status == 401 then
              auth = "no"; say("sis", "Claude Code no tiene sesion iniciada en esta Mac. Toca «Conectar con Claude».")
            else say("sis", "Error: " .. tostring(ev.result)) end
          end
        end
      end
    elseif linea:match("^__FIN__") then
      if corriendo then corriendo = false; say("sis", "Claude Code termino sin respuesta (" .. linea .. "). Mira turno_" .. turno .. ".jsonl") end
    end
  end
end

local ult_clip, clip_pend, clip_t = (R.CF_GetClipboard and R.CF_GetClipboard("") or ""), nil, 0
local PRUEBA = false
local pend = {}   -- mensajes escritos mientras Claude trabaja: salen juntos apenas termina
local function enviar()
  local t = entrada:gsub("^%s+", ""):gsub("%s+$", "")
  if t == "" then return end
  entrada = ""
  say("yo", t); foco = true; ultimo_pedido = (ultimo_pedido .. " " .. t):sub(-600)
  if corriendo then pend[#pend + 1] = t else lanzar(t) end
end

---------------------------------------------------------------- ventana (estilo app de Claude, colores del tema activo de REAPER)
local function tema(nombre, def)
  local ok, c = pcall(R.GetThemeColor, nombre, 0)
  if not ok or not c or c < 0 then return def end
  local r, g, b = R.ColorFromNative(c & 0xFFFFFF)
  return (r << 24) | (g << 16) | (b << 8) | 0xFF
end
local function mezcla(a, b, t)   -- t=0 -> a, t=1 -> b (colores 0xRRGGBBAA)
  local function ch(c, sh) return (c >> sh) & 0xFF end
  local o = 0
  for _, sh in ipairs({24, 16, 8}) do o = o | (math.floor(ch(a, sh) + (ch(b, sh) - ch(a, sh)) * t + .5) << sh) end
  return o | 0xFF
end
local NARANJA = 0xD97757FF
local C = {}
local function colores()
  C.fondo = tema("col_main_bg2", 0x2B2B2BFF)
  C.texto = 0xFFFFFFFF
  C.suave = mezcla(C.fondo, C.texto, 0.6)
  C.burbuja = mezcla(C.fondo, C.texto, 0.12)
  C.caja = mezcla(C.fondo, 0x000000FF, 0.25)
end

local pos_dock_hecha, traer_fx = false, nil
-- donde se acopla el chat: 3 = derecha (pestaña junto al FX Browser), 1 = izquierda, 0 = abajo
local POS_DOCK = 3
local DOCK_NRO = 2   -- que docker de ese lado: 1 = el primero (donde suele estar el FX Browser), 2 = el segundo (apilado aparte)
local function dock_derecho()
  local n = 0
  for i = 0, 15 do
    local ok, p = pcall(R.DockGetPosition, i)
    if ok and p == POS_DOCK then n = n + 1; if n == DOCK_NRO then return -(i + 1) end end
  end
end

local function burbuja_usuario(txt)
  local ancho = ImGui.GetContentRegionAvail(ctx)
  local wrap = ancho * 0.82
  local tw, th = ImGui.CalcTextSize(ctx, txt, nil, nil, false, wrap - 24)
  local bw = math.min(wrap, tw + 24)
  local x0, y0 = ImGui.GetCursorScreenPos(ctx)
  local dl = ImGui.GetWindowDrawList(ctx)
  local xr = x0 + ancho - bw
  ImGui.DrawList_AddRectFilled(dl, xr, y0, xr + bw, y0 + th + 20, C.burbuja, 14)
  ImGui.SetCursorScreenPos(ctx, xr + 12, y0 + 10)
  ImGui.PushStyleColor(ctx, ImGui.Col_Text, C.texto)
  ImGui.PushTextWrapPos(ctx, ImGui.GetCursorPosX(ctx) + bw - 24)
  ImGui.TextWrapped(ctx, txt)
  ImGui.PopTextWrapPos(ctx); ImGui.PopStyleColor(ctx)
  ImGui.SetCursorScreenPos(ctx, x0, y0 + th + 20 + 12)
end

local function loop()
  leer_auth()
  if PRUEBA and not corriendo then
    PRUEBA = false
    entrada = "Prueba de conexion: decime en una linea cuantas pistas tiene esta sesion de REAPER (usa cable lua)."; enviar()
  end
  if rfile(BASE .. "/stop.txt") then os.remove(BASE .. "/stop.txt"); return end
  procesar_cola()
  if corriendo then leer_salida() end
  if not corriendo and #pend > 0 then
    local t = table.concat(pend, "\n"); pend = {}; lanzar(t)
  end
  colores()
  if not pos_dock_hecha then
    pos_dock_hecha = true
    local d = dock_derecho(); if d then ImGui.SetNextWindowDockID(ctx, d) end
    traer_fx = nil
  end
  if traer_fx then   -- al abrir, el FX Browser queda al frente como siempre; el chat es la pestaña de al lado
    traer_fx = traer_fx - 1
    if traer_fx == 0 then
      traer_fx = nil
      if R.GetToggleCommandState(40271) == 0 then R.Main_OnCommand(40271, 0) end
    end
  end
  ImGui.SetNextWindowSize(ctx, 420, 640, ImGui.Cond_FirstUseEver)
  ImGui.PushStyleColor(ctx, ImGui.Col_WindowBg, C.fondo)
  ImGui.PushStyleColor(ctx, ImGui.Col_ChildBg, C.fondo)
  ImGui.PushStyleColor(ctx, ImGui.Col_Text, C.texto)
  ImGui.PushStyleColor(ctx, ImGui.Col_FrameBg, C.caja)
  ImGui.PushStyleColor(ctx, ImGui.Col_Border, C.burbuja)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_WindowPadding, 16, 14)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_FrameRounding, 12)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 12, 10)
  ImGui.PushStyleVar(ctx, ImGui.StyleVar_ItemSpacing, 8, 10)
  if fuente then ImGui.PushFont(ctx, fuente, 15) end
  local visible, open = ImGui.Begin(ctx, "Agent Cable", true)
  if visible then
    if ImGui.IsWindowFocused(ctx, ImGui.FocusedFlags_RootAndChildWindows) then ImGui.SetNextFrameWantCaptureKeyboard(ctx, true) end
    local _, alto = ImGui.GetContentRegionAvail(ctx)
    if ImGui.BeginChild(ctx, "hist", 0, alto - 70) then
      if #msgs == 0 then
        ImGui.PushStyleColor(ctx, ImGui.Col_Text, NARANJA)
        ImGui.Text(ctx, "Agent Cable")
        ImGui.PopStyleColor(ctx)
        ImGui.PushStyleColor(ctx, ImGui.Col_Text, C.suave)
        ImGui.TextWrapped(ctx, "Contame que queres hacer en esta sesion. Por ejemplo: armar la sesion con los audios de una carpeta, pasar eses a las voces o exportar stems.")
        ImGui.PopStyleColor(ctx)
      end
      for _, m in ipairs(msgs) do
        if m.rol == "yo" then burbuja_usuario(m.txt)
        else
          ImGui.PushStyleColor(ctx, ImGui.Col_Text, m.rol == "claude" and C.texto or (m.rol == "sis" and C.suave or C.suave))
          ImGui.TextWrapped(ctx, (m.rol == "paso" and "· " or "") .. m.txt)
          ImGui.PopStyleColor(ctx)
        end
      end
      if corriendo then
        ImGui.PushStyleColor(ctx, ImGui.Col_Text, NARANJA)
        ImGui.Text(ctx, string.format("Claude trabajando... %.0f s", R.time_precise() - t0))
        ImGui.PopStyleColor(ctx)
      end
      if scroll_abajo then ImGui.SetScrollHereY(ctx, 1); scroll_abajo = false end
      ImGui.EndChild(ctx)
    end
    if auth == "no" or auth == "login" then
      ImGui.PushStyleColor(ctx, ImGui.Col_Text, NARANJA)
      ImGui.TextWrapped(ctx, auth == "no" and "Claude Code no tiene sesion iniciada en esta Mac." or "Termina el inicio de sesion en la ventana de Terminal que se abrio (es el flujo oficial de Anthropic). Esto sigue solo cuando termines.")
      ImGui.PopStyleColor(ctx)
      if auth == "no" then
        ImGui.PushStyleColor(ctx, ImGui.Col_Button, NARANJA)
        if ImGui.Button(ctx, "Iniciar sesion (abre la Terminal)", -1, 0) then conectar(); esperando_prueba = true end
        ImGui.PopStyleColor(ctx)
      elseif ImGui.SmallButton(ctx, "Reintentar") then conectar() end
    end
    if foco and auth ~= "login" then ImGui.SetKeyboardFocusHere(ctx); foco = false end
    ImGui.SetNextItemWidth(ctx, -64)
    local antes = entrada
    local pego = false
    do local ok, v = pcall(function() return ImGui.IsKeyChordPressed(ctx, ImGui.Mod_Super | ImGui.Key_V) or ImGui.IsKeyChordPressed(ctx, ImGui.Mod_Ctrl | ImGui.Key_V) end); pego = ok and v end
    local enter; enter, entrada = ImGui.InputTextWithHint(ctx, "##entrada", "Pedile algo a Claude...", entrada, ImGui.InputTextFlags_EnterReturnsTrue)
    if pego and entrada == antes and R.CF_GetClipboard then entrada = entrada .. R.CF_GetClipboard("") end  -- respaldo si REAPER se come el Cmd+V
    -- respaldo para dictado/pegado por portapapeles: si el portapapeles cambia con el chat enfocado y el texto no entro solo, se agrega
    if R.CF_GetClipboard then
      local clip = R.CF_GetClipboard("")
      local activo = ImGui.IsWindowFocused(ctx, ImGui.FocusedFlags_RootAndChildWindows) or ImGui.IsWindowHovered(ctx, ImGui.HoveredFlags_RootAndChildWindows)
      if not activo then
        ult_clip, clip_pend = clip, nil          -- sin foco: solo se sigue el portapapeles, no se pega nada
      else
        if clip ~= ult_clip then ult_clip = clip; clip_pend, clip_t = clip, R.time_precise() end
        if clip_pend and R.time_precise() - clip_t > 0.3 then
          if clip_pend ~= "" and entrada:sub(-#clip_pend) ~= clip_pend then entrada = entrada .. clip_pend end
          clip_pend = nil
        end
      end
    end
    ImGui.SameLine(ctx)
    ImGui.PushStyleColor(ctx, ImGui.Col_Button, NARANJA)
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, mezcla(NARANJA, 0xFFFFFFFF, 0.15))
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonActive, mezcla(NARANJA, 0x000000FF, 0.2))
    ImGui.PushStyleColor(ctx, ImGui.Col_Text, 0xFFFFFFFF)
    if ImGui.Button(ctx, corriendo and "..." or "Enviar", 56, 0) or enter then enviar() end
    ImGui.PopStyleColor(ctx, 4)
    -- selector de modelo/esfuerzo: chico, sin azul, pegado a la derecha
    local etiqueta = MODELOS[m_i][1] .. " · " .. ESFUERZOS[e_i][1]
    local tw = ImGui.CalcTextSize(ctx, etiqueta)
    local ancho = tw + 26
    ImGui.SetCursorPosX(ctx, ImGui.GetCursorPosX(ctx) + ImGui.GetContentRegionAvail(ctx) - ancho)
    ImGui.PushStyleColor(ctx, ImGui.Col_Text, C.suave)
    ImGui.PushStyleColor(ctx, ImGui.Col_FrameBg, 0x00000000)
    ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgHovered, C.burbuja)
    ImGui.PushStyleColor(ctx, ImGui.Col_FrameBgActive, C.burbuja)
    ImGui.PushStyleColor(ctx, ImGui.Col_Button, 0x00000000)
    ImGui.PushStyleColor(ctx, ImGui.Col_ButtonHovered, 0x00000000)
    ImGui.PushStyleColor(ctx, ImGui.Col_PopupBg, C.caja)
    ImGui.PushStyleColor(ctx, ImGui.Col_Header, C.burbuja)
    ImGui.PushStyleColor(ctx, ImGui.Col_HeaderHovered, C.burbuja)
    ImGui.PushStyleColor(ctx, ImGui.Col_HeaderActive, C.burbuja)
    ImGui.PushStyleVar(ctx, ImGui.StyleVar_FramePadding, 6, 2)
    ImGui.SetNextItemWidth(ctx, ancho)
    if ImGui.BeginCombo(ctx, "##modelo", etiqueta, ImGui.ComboFlags_NoArrowButton) then
      for i, m in ipairs(MODELOS) do
        if ImGui.Selectable(ctx, m[1], i == m_i) then m_i = i; guardar_cfg() end
      end
      ImGui.Separator(ctx)
      for i, e in ipairs(ESFUERZOS) do
        if ImGui.Selectable(ctx, "Esfuerzo " .. e[1], i == e_i) then e_i = i; guardar_cfg() end
      end
      ImGui.EndCombo(ctx)
    end
    if modelo_real and ImGui.IsItemHovered(ctx) then ImGui.SetTooltip(ctx, "Respondio: " .. modelo_real) end
    ImGui.PopStyleVar(ctx, 1); ImGui.PopStyleColor(ctx, 10)
    ImGui.End(ctx)
  end
  if fuente then ImGui.PopFont(ctx) end
  ImGui.PopStyleVar(ctx, 4); ImGui.PopStyleColor(ctx, 5)
  if open then R.defer(loop) end
end

R.defer(loop)
