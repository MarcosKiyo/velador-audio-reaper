-- cable_lib.lua: funciones listas para `cable lua` (disponibles como `lib`). Sin dependencias; cada llamado de cable ya es un paso de deshacer.
-- Baterias MIDI con velocity humanizada, capas de pistas con volumen/pan coherentes y nivelado por medicion.
local R = reaper
local M = {}

M.GM = {kick = 36, rim = 37, snare = 38, clap = 39, hat = 42, hat_pedal = 44, hat_open = 46, tom_lo = 45, tom_mid = 47, tom_hi = 50,
        crash = 49, ride = 51, cowbell = 56, shaker = 70, conga_hi = 62, conga_lo = 64}

M.COLORES = {BATERIA = {200, 70, 60}, BAJO = {60, 110, 220}, SYNTH = {150, 80, 200}, GUITARRAS = {220, 140, 50},
             AMBIENTES = {70, 170, 140}, VOCES = {235, 200, 60}, PERC = {230, 110, 150}, REF = {128, 128, 128}}

-- nivel relativo por familia (dB respecto de la bateria = 0) y panorama; heuristica de arranque, el usuario ajusta
M.NIVEL_DB = {BATERIA = 0, BAJO = -2, SYNTH = -9, GUITARRAS = -7, AMBIENTES = -14, VOCES = -3, PERC = -10, REF = -12}
M.OBJETIVO_RMS_BATERIA = -22   -- dB RMS de la familia de referencia; el resto = esto + NIVEL_DB

function M.db(x) return 10 ^ (x / 20) end

function M.pista(nombre, familia)
  local i = R.CountTracks(0)
  R.InsertTrackAtIndex(i, false)
  local tr = R.GetTrack(0, i)
  R.GetSetMediaTrackInfo_String(tr, "P_NAME", nombre, true)
  local c = M.COLORES[familia]
  if c then R.SetTrackColor(tr, R.ColorToNative(c[1], c[2], c[3]) | 0x1000000) end
  return tr
end

-- patrones de 16 pasos por corchea semicorchea: digito = velocity relativa (9 fuerte, 6 medio, 3 fantasma), . = nada
M.ESTILOS = {
  rock    = {kick = "9...5...9.5.....", snare = "....9.......9..3", hat = "7.5.7.5.7.5.7.5."},
  four    = {kick = "9...9...9...9...", clap = "....9.......9...", hat = "..7...7...7...7.", hat_open = "..5...5...5...5."},
  boombap = {kick = "9.....5...9..5..", snare = "....9.......9..3", hat = "7.5.7.5.7.5.7.55"},
  funk    = {kick = "9..5..5...9..5..", snare = "....9..3.3..9..3", hat = "7575757575757575"},
  afro    = {kick = "9..5..9...5.9...", rim = "..9...9...9...9.", shaker = "5353535353535353", conga_lo = ".....9.....9...."},
}

local function rnd(seed) local s = seed or 7; return function() s = (s * 1103515245 + 12345) % 2147483648; return s / 2147483648 end end

-- groove(track, {estilo="rock", compases=8, humanizar=25, seed=7, relleno=true, tempo=nil, mapa=M.GM})
-- crea un item MIDI con velocity humanizada: nunca dos golpes iguales seguidos por instrumento (regla de oro), cola de relleno al final de cada 4 compases
function M.groove(tr, o)
  o = o or {}
  local patron = type(o.estilo) == "table" and o.estilo or M.ESTILOS[o.estilo or "rock"]
  assert(patron, "estilo desconocido; usa " .. table.concat((function() local t = {} for k in pairs(M.ESTILOS) do t[#t + 1] = k end return t end)(), ", "))
  local mapa, compases, hum = o.mapa or M.GM, o.compases or 8, (o.humanizar or 25) / 100
  local tempo = o.tempo or R.Master_GetTempo()
  local beat = 60 / tempo
  local r = rnd(o.seed)
  local t0 = o.inicio or R.GetCursorPosition()
  local item = R.CreateNewMIDIItemInProj(tr, t0, t0 + compases * 4 * beat, false)
  local take = R.GetActiveTake(item)
  local ultimo = {}
  local function nota(instr, paso_beats, vel, largo)
    local pitch = mapa[instr]; if not pitch then return end
    local v = math.floor(vel * (0.88 + 0.12 * r()) + (r() - .5) * 18 * hum + .5)
    if ultimo[instr] == v then v = v + ((r() < .5) and -3 or 3) end   -- regla de oro
    v = math.max(1, math.min(127, v)); ultimo[instr] = v
    local jitter = (r() - .5) * 0.03 * hum   -- hasta ~±15 ms a 100 %
    local ppq0 = R.MIDI_GetPPQPosFromProjTime(take, t0 + (paso_beats + jitter) * beat)
    local ppq1 = R.MIDI_GetPPQPosFromProjTime(take, t0 + (paso_beats + (largo or 0.2)) * beat)
    R.MIDI_InsertNote(take, false, false, ppq0, ppq1, 9, pitch, v, true)
  end
  for c = 0, compases - 1 do
    local es_relleno = (o.relleno ~= false) and ((c + 1) % 4 == 0)
    for instr, pat in pairs(patron) do
      for p = 1, 16 do
        local ch = pat:sub(p, p)
        if ch ~= "." and not (es_relleno and p > 12 and (instr == "kick" or instr == "snare")) then
          nota(instr, c * 4 + (p - 1) / 4, 12 * tonumber(ch) + 4)
        end
      end
    end
    if es_relleno then   -- relleno de toms: crescendo hasta el crash del compas siguiente
      local toms = {"tom_hi", "tom_hi", "tom_mid", "tom_lo"}
      for k = 0, 3 do nota(toms[k + 1], c * 4 + 3 + k * 0.25, 70 + k * 14) end
      nota("crash", (c + 1) * 4, 112)
    end
  end
  R.MIDI_Sort(take)
  return item
end

-- capas(lista, {carpeta=true}): lista = { {nombre, familia, archivo|nil}, ... }
-- crea las pistas (carpeta por familia opcional), pone volumen por familia y panorama repartido, y deja los audios en el compas 1
function M.capas(lista, o)
  o = o or {}
  local por_familia, orden = {}, {}
  for _, e in ipairs(lista) do
    if not por_familia[e[2]] then por_familia[e[2]] = {}; orden[#orden + 1] = e[2] end
    table.insert(por_familia[e[2]], e)
  end
  local creadas = {}
  for _, fam in ipairs(orden) do
    local carp
    if o.carpeta ~= false and #por_familia[fam] > 1 then
      carp = M.pista(fam, fam); R.SetMediaTrackInfo_Value(carp, "I_FOLDERDEPTH", 1)
    end
    local hijos = por_familia[fam]
    for j, e in ipairs(hijos) do
      local tr = M.pista(e[1], fam)
      local pan = 0
      if #hijos > 1 and fam ~= "BAJO" and fam ~= "VOCES" then pan = (j % 2 == 0 and 1 or -1) * math.min(0.8, 0.25 + 0.15 * math.floor(j / 2)) end
      if fam == "AMBIENTES" and #hijos > 1 then pan = (j % 2 == 0 and 1 or -1) * 0.9 end
      R.SetMediaTrackInfo_Value(tr, "D_PAN", pan)
      R.SetMediaTrackInfo_Value(tr, "D_VOL", M.db(M.NIVEL_DB[fam] or -9))
      if e[3] then
        R.Main_OnCommand(40297, 0); R.SetTrackSelected(tr, true); R.Main_OnCommand(40914, 0); R.SetEditCurPos(0, false, false)
        R.InsertMedia(e[3], 0)
        if fam == "REF" then R.SetMediaTrackInfo_Value(tr, "B_MUTE", 1) end
      end
      if carp and j == #hijos then R.SetMediaTrackInfo_Value(tr, "I_FOLDERDEPTH", -1) end
      creadas[#creadas + 1] = tr
    end
  end
  return creadas
end

-- rms_db(track, segundos): RMS (dB) de lo que suena en el primer item de audio, ventanas activas (> -60 dB), maximo `segundos`
function M.rms_db(tr, seg)
  local it = R.GetTrackMediaItem(tr, 0); if not it then return nil end
  local tk = R.GetActiveTake(it); if not tk or R.TakeIsMIDI(tk) then return nil end
  local src = R.GetMediaItemTake_Source(tk)
  local sr, nch = R.GetMediaSourceSampleRate(src), math.max(R.GetMediaSourceNumChannels(src), 1)
  local len = math.min(R.GetMediaSourceLength(src) or 0, seg or 30)
  if len <= 0 then return nil end
  local acc = R.CreateTakeAudioAccessor(tk)
  local blk, suma, n = 4096, 0, 0
  local buf = R.new_array(blk * nch)
  local t = 0
  while t < len do
    buf.clear(); R.GetAudioAccessorSamples(acc, sr, nch, t, blk, buf)
    local s, c = 0, 0
    for i = 1, blk * nch do local v = buf[i]; s = s + v * v; c = c + 1 end
    if c > 0 and 10 * math.log(s / c + 1e-12, 10) > -60 then suma = suma + s; n = n + c end
    t = t + blk / sr
  end
  R.DestroyAudioAccessor(acc)
  if n == 0 then return nil end
  return 10 * math.log(suma / n, 10)
end

-- nivelar(familias_por_pista, objetivo_bateria_db): ajusta D_VOL de cada pista de audio para que su RMS = objetivo + NIVEL_DB[familia]
-- tabla = { [pista]=familia }. Devuelve lista de {nombre, antes_rms, vol_db}
function M.nivelar(tabla, objetivo)
  objetivo = objetivo or M.OBJETIVO_RMS_BATERIA
  local out = {}
  for tr, fam in pairs(tabla) do
    local rms = M.rms_db(tr, 30)
    if rms then
      local meta = objetivo + (M.NIVEL_DB[fam] or -9)
      local vol = math.max(-30, math.min(12, meta - rms))
      R.SetMediaTrackInfo_Value(tr, "D_VOL", M.db(vol))
      local _, nom = R.GetSetMediaTrackInfo_String(tr, "P_NAME", "", false)
      out[#out + 1] = {nom, rms, vol}
    end
  end
  return out
end

return M
