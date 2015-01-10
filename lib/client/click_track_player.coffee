class BeatDetector.ClickTrackPlayer
  constructor: (@_audioContext, @_timeline) ->
    BeatDetector.loadAudioFromUrl '/metronome.ogg', (arrayBuffer) =>
      @_metronomeAudioSample = new BeatDetector.ArrayBufferAudioSample(
        arrayBuffer)
      @_metronomeAudioSample.loadAudio @_audioContext

  play: (beatManager, playWithClick) ->
    @_beatsClone = beatManager.getBeats().slice(0)
    @_audioSample = beatManager.getAudioSample()
    @_trackStartTime = 0
    return unless @_audioSample?

    @_metronomeClickHasBeenScheduled = false

    @_trackLength = beatManager.getTrackLengthSeconds()

    while @_beatsClone.length and @_beatsClone[0] < @_trackStartTime
      @_beatsClone.splice(0, 1)

    if @_audioSample.playing
      return @_audioSample.stop()
    gain = if playWithClick
      0.3
    else
      1
    console.log playWithClick
    @_audioSample.tryPlay(@_trackStartTime, gain)
    @_startTime = @_audioContext.currentTime

    requestAnimationFrame(@_update)

  _update: =>
    playbackTime = @_audioContext.currentTime - @_startTime + @_trackStartTime
    if playbackTime > @_trackLength
      @_audioSample.stop()
      Session.set 'playing', @_audioSample.playing
      # @_timeline.render(@_trackStartTime)
    return unless @_audioSample.playing
    # @_timeline.render(playbackTime)
    # Schedule metronome clicks so we they happen accurately
    # see:
    # http://www.html5rocks.com/en/tutorials/audio/scheduling/
    if not @_metronomeClickHasBeenScheduled and \
        @_metronomeAudioSample? \
        and @_beatsClone.length > 0
      nextBeatScheduleTime = @_audioContext.currentTime \
          - playbackTime + @_beatsClone[0]
      @_metronomeAudioSample.tryPlay(
        undefined,
        undefined,
        nextBeatScheduleTime
      )
      @_metronomeClickHasBeenScheduled = true
    if @_beatsClone.length > 0 and @_beatsClone[0] <= playbackTime
      #Beat!
      if @_beatsClone.length > 2
        beatTime = @_beatsClone[1] - @_beatsClone[0]
      #beatVisualisation.render(beatTime / 2)
      @_beatsClone.splice(0, 1)
      @_metronomeClickHasBeenScheduled = false
    requestAnimationFrame(@_update)

