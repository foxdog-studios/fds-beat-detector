THRESHOLD_CONSTANT = 6
VARIANCE_COEFFICIENT = 0
SAMPLES_PER_INSTANT_ENERGY = 300
NUMBER_OF_PREVIOUS_SAMPLES = 42
MAX_BPM = 253
SAMPLE_RATE = 44100
CHANNELS = 1

getAudioContext = ->
  AudioContext = window.AudioContext or window.webkitAudioContext
  unless audioContext?
    audioContext = new AudioContext()
  audioContext

getOfflineAudioContext = (channels, length, sampleRate) ->
  OfflineAudioContext = \
      window.OfflineAudioContext or window.webkitOfflineAudioContext
  new OfflineAudioContext(channels, length, sampleRate)

class BeatDetector.BeatManager
  constructor: ->
    @_arrayBuffer = new ReactiveVar()
    @_pcmAudioData = new ReactiveVar(false)
    @_hasAudio = new ReactiveVar(false)
    @_previousAverageEnergyCoefficient = new ReactiveVar(THRESHOLD_CONSTANT)
    @_varianceCoefficient = new ReactiveVar(VARIANCE_COEFFICIENT)
    @_samplesPerInstantEnergy = new ReactiveVar(SAMPLES_PER_INSTANT_ENERGY)
    @_numberOfPreviousEnergies = new ReactiveVar(NUMBER_OF_PREVIOUS_SAMPLES)
    @_maxBpm = new ReactiveVar(MAX_BPM)
    @_trackLengthSeconds = new ReactiveVar(0)
    @_currentBpm = new ReactiveVar(0)
    @_beatDetector = new ReactiveVar(null)

  getArrayBuffer: ->
    @_arrayBuffer.get()

  setArrayBuffer: (arrayBuffer) ->
    @_arrayBuffer.set(arrayBuffer)

  getPcmAudioData: ->
    @_pcmAudioData.get()

  hasAudio: ->
    @_hasAudio.get()

  getPreviousAverageEnergyCoefficient: ->
    @_previousAverageEnergyCoefficient.get()

  setPreviousAverageEnergyCoefficient: (previousAverageEnergyCoefficient) ->
    @_previousAverageEnergyCoefficient.set(previousAverageEnergyCoefficient)

  getCurrentBpm: ->
    @_currentBpm.get()

  fromUrl: (url) ->
    BeatDetector.loadAudioFromUrl url, @_updateAudioFromArrayBuffer

  _updateAudioFromArrayBuffer: (arrayBuffer) =>
    @_pcmAudioData.set null
    @_hasAudio.set false
    @_arrayBuffer.set(arrayBuffer)

    audioContext = getAudioContext()
    audioSample = new BeatDetector.ArrayBufferAudioSample(arrayBuffer)

    # XXX: To know the correct length we need to make the offline audio context,
    # we need to decode the audio, using an AudioContext (which we also use for
    # playback).
    audioSample.loadAudio audioContext, @_onAudioLoaded

  _onAudioLoaded: (audioSample) =>
    @_hasAudio.set true

    pcmAudioSample = new BeatDetector.ArrayBufferAudioSample(
      @_arrayBuffer.get()
    )
    length = audioSample.buffer.length
    @_trackLengthSeconds.set length / SAMPLE_RATE
    offlineAudioContext = \
        getOfflineAudioContext(CHANNELS, length, SAMPLE_RATE)
    pcmAudioGenerator = new BeatDetector.PcmAudioGenerator()
    pcmAudioGenerator.getPcmAudioData(
      offlineAudioContext,
      pcmAudioSample,
      @_updateAudioFromPcmData
    )

  _updateAudioFromPcmData: (pcmAudioData) =>
    @_pcmAudioData.set(pcmAudioData)
    @_updateBeats()

  _updateBeats: ->
    beatDetector = new BeatDetector.BeatDetector()
    beatDetector.detectBeats(
      @_pcmAudioData.get(),
      @_varianceCoefficient.get(),
      @_previousAverageEnergyCoefficient.get(),
      @_samplesPerInstantEnergy.get(),
      @_numberOfPreviousEnergies.get(),
      @_maxBpm.get()
    )
    @_currentBpm.set beatDetector.bpm
    @_beatDetector.set(beatDetector)

