class BeatDetector.ClickTrackPlayer
  constructor: (@_audioContext, @_timeline, @_beatFlash) ->
    @_playing = new ReactiveVar(false)
    @_frameHandle = null
    @_playWithClick = new ReactiveVar(false)
    @_playbackRate = new ReactiveVar(1)
    sampleUrl = '/packages/fds_beat-detector/lib/assets/metronome.ogg'
    BeatDetector.loadAudioFromUrl sampleUrl, (arrayBuffer) =>
      @_metronomeAudioSample = new BeatDetector.ArrayBufferAudioSample(
        arrayBuffer)
      @_metronomeAudioSample.loadAudio @_audioContext

  getPlaybackRate: ->
    @_playbackRate.get()

  setPlaybackRate: (playbackRate) ->
    @_playbackRate.set(playbackRate)

  play: (@_beatManager, options = {}) ->
    options = _.defaults options,
      startTime: 0
      audioStartTime: @_audioContext.currentTime

    @stop()

    @_playing.set true

    @_beatsClone = @_beatManager.getBeats().slice(0)
    @_startTime = options.startTime / @_playbackRate.get()

    @_metronomeClickHasBeenScheduled = false

    @_trackLength = @_beatManager.getTrackLengthSeconds()

    while @_beatsClone.length and @_beatsClone[0] < @_startTime
      @_beatsClone.splice(0, 1)

    @_audioStartTime = options.audioStartTime

    @_frameHandle = requestAnimationFrame(@_update)

  stop: ->
    if @_frameHandle?
      cancelAnimationFrame @_frameHandle
    if @_metronomeAudioSample?
      @_metronomeAudioSample.stop()
    @_playing.set false

  isPlaying: ->
    @_playing.get()

  setPlayWithClick: (state) ->
    @_playWithClick.set state

  getPlayWithClick: ->
    @_playWithClick.get()

  _update: =>
    @_frameHandle = null

    distanceFromStartTime = @_audioContext.currentTime - @_audioStartTime

    if distanceFromStartTime < 0
      @_frameHandle = requestAnimationFrame(@_update)
      return

    playbackTime = @_audioContext.currentTime - @_audioStartTime + \
      @_startTime / @_playbackRate.get()
    @_trackLength = @_beatManager.getTrackLengthSeconds() / @_playbackRate.get()
    if playbackTime > @_trackLength
      @_timeline.render(@_startTime, 0, @_trackLength)
      @_playing.set false

    unless @_playing.get()
      return

    @_timeline.render(playbackTime, 0, @_trackLength)

    # Schedule metronome clicks so we they happen accurately
    # see:
    # http://www.html5rocks.com/en/tutorials/audio/scheduling/
    if not @_metronomeClickHasBeenScheduled \
        and @_metronomeAudioSample? \
        and @_beatsClone.length > 0 \
        and @_playWithClick.get()
      nextBeatScheduleTime = @_audioContext.currentTime \
          - playbackTime + @_beatsClone[0] / @_playbackRate.get()
      @_metronomeAudioSample.tryPlay(
        undefined,
        undefined,
        nextBeatScheduleTime
      )
      @_metronomeClickHasBeenScheduled = true

    if @_beatsClone.length > 0 \
        and @_beatsClone[0] / @_playbackRate.get() <= playbackTime
      #Beat!
      @_beatFlash.render(50)
      @_beatsClone.splice(0, 1)
      @_metronomeClickHasBeenScheduled = false
    @_frameHandle = requestAnimationFrame(@_update)

