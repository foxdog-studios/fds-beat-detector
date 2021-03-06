THRESHOLD_CONSTANT = 6
VARIANCE_COEFFICIENT = 0
SAMPLES_PER_INSTANT_ENERGY = 300
NUMBER_OF_PREVIOUS_SAMPLES = 42
MAX_BPM = 253
CHANNELS = 1

BeatDetector.getAudioContext = ->
  AudioContext = window.AudioContext or window.webkitAudioContext
  unless audioContext?
    audioContext = new AudioContext()
  audioContext

getOfflineAudioContext = (channels, length, sampleRate) ->
  OfflineAudioContext = \
      window.OfflineAudioContext or window.webkitOfflineAudioContext
  new OfflineAudioContext(channels, length, sampleRate)


getWorker = ->
  workerUrl = \
    '/packages/fds_beat-detector/lib/assets/worker/beat_detector_worker.js'
  new Worker workerUrl

class BeatDetector.BeatManager
  constructor: (@_audioContext) ->
    @_arrayBuffer = new ReactiveVar()
    @_audioSample = new ReactiveVar()
    @_pcmAudioData = new ReactiveVar(false)
    @_previousAverageEnergyCoefficient = new ReactiveVar(THRESHOLD_CONSTANT)
    @_varianceCoefficient = new ReactiveVar(VARIANCE_COEFFICIENT)
    @_samplesPerInstantEnergy = new ReactiveVar(SAMPLES_PER_INSTANT_ENERGY)
    @_numberOfPreviousEnergies = new ReactiveVar(NUMBER_OF_PREVIOUS_SAMPLES)
    @_maxBpm = new ReactiveVar(MAX_BPM)
    @_trackLengthSeconds = new ReactiveVar(0)
    @_currentBpm = new ReactiveVar(null)
    @_principalBeatTime = new ReactiveVar(null)
    @_maxEnergy = new ReactiveVar(null)
    @_energies = new ReactiveVar([])
    @_averageEnergies = new ReactiveVar([])
    @_beats = new ReactiveVar([])
    @_interpolatedBeats = new ReactiveVar([])
    @_maximumEnergies = new ReactiveVar([])
    @_worker = getWorker()

    @_worker.addEventListener 'message', @_onWorkerMessage

  _onWorkerMessage: (event) =>
    beatDetector = event.data
    @_currentBpm.set beatDetector.bpm
    @_principalBeatTime.set beatDetector.principalBeatTime
    @_maxEnergy.set beatDetector.maxEnergy
    @_energies.set beatDetector.energies
    @_averageEnergies.set beatDetector.averageEnergies
    @_beats.set beatDetector.beats
    @_interpolatedBeats.set beatDetector.interpolatedBeats
    @_maximumEnergies.set beatDetector.maximumEnergies

  getArrayBuffer: ->
    @_arrayBuffer.get()

  setArrayBuffer: (arrayBuffer) ->
    @_arrayBuffer.set(arrayBuffer)

  getAudioSample: ->
    @_audioSample.get()

  getPcmAudioData: ->
    @_pcmAudioData.get()

  getPreviousAverageEnergyCoefficient: ->
    @_previousAverageEnergyCoefficient.get()

  setPreviousAverageEnergyCoefficient: (previousAverageEnergyCoefficient) ->
    @_previousAverageEnergyCoefficient.set(previousAverageEnergyCoefficient)

  getCurrentBpm: ->
    @_currentBpm.get()

  getPrincipalBeatTime: ->
    @_principalBeatTime.get()

  getMaxEnergy: ->
    @_maxEnergy.get()

  getEnergies: ->
    @_energies.get()

  getAverageEnergies: ->
    @_averageEnergies.get()

  getMaximumEnergies: ->
    @_maximumEnergies.get()

  getBeats: ->
    @_beats.get()

  getInterpolatedBeats: ->
    @_interpolatedBeats.get()

  getTrackLengthSeconds: ->
    @_trackLengthSeconds.get()

  fromUrl: (url) ->
    BeatDetector.loadAudioFromUrl url, @_updateAudioFromArrayBuffer

  _updateAudioFromArrayBuffer: (arrayBuffer) =>
    @_pcmAudioData.set null
    @_audioSample.set null
    @_arrayBuffer.set(arrayBuffer)

    audioSample = new BeatDetector.ArrayBufferAudioSample(arrayBuffer)

    # XXX: To know the correct length we need to make the offline audio context,
    # we need to decode the audio, using an AudioContext (which we also use for
    # playback).
    audioSample.loadAudio @_audioContext, @_onAudioLoaded

  _onAudioLoaded: (audioSample) =>
    @_audioSample.set(audioSample)
    pcmAudioSample = new BeatDetector.ArrayBufferAudioSample(
      @_arrayBuffer.get()
    )
    length = audioSample.buffer.length
    @_trackLengthSeconds.set length / @_audioContext.sampleRate
    offlineAudioContext = \
        getOfflineAudioContext(CHANNELS, length, @_audioContext.sampleRate)
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
    @_worker.postMessage
      pcmData: @_pcmAudioData.get()
      previousEnergyVarianceCoefficient: @_varianceCoefficient.get()
      previousAverageEnergyCoefficient: @_previousAverageEnergyCoefficient.get(),
      samplesPerInstantEnergy: @_samplesPerInstantEnergy.get()
      numberOfPreviousSamples: @_numberOfPreviousEnergies.get()
      maxBpm: @_maxBpm.get()
      sampleRate: @_audioContext.sampleRate

