local snd <const> = playdate.sound

BOUNCE_SCALE = {
  "F2", "G2", "A3", "Bb3", "C3", "D3", "E3"
}

local bounceSynth = snd.synth.new(snd.kWaveSquare)
bounceSynth:setADSR(0, 0.5, 0, 0.3)
local bounceLFO = snd.lfo.new(snd.kLFOSampleAndHold)
bounceLFO:setRate(1)
bounceSynth:setFrequencyMod(bounceLFO)
local bounceChannel = snd.channel.new()
bounceChannel:addSource(bounceSynth)
function Bounce(n)
  n = n or 1
  bounceSynth:playNote(BOUNCE_SCALE[n // 20 + 1])
end

local explosionSynth = snd.synth.new(snd.kWaveNoise)
explosionSynth:setADSR(0, 0, 1, 1)
local explosionChannel = snd.channel.new()
explosionChannel:addSource(explosionSynth)
function Explode(n)
  explosionSynth:playNote(BOUNCE_SCALE[n // 20 + 1], 1, 1)
end
