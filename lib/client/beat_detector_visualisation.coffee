class BeatDetector.BeatDetectorVisualisation
  constructor: (@_cvs) ->
    @_ctx = @_cvs.getContext '2d'
    @_cvs.width = $(@_cvs).width()

  render: (beatManager, start, end) ->
    @_cvs.width = @_cvs.width

    beatsHeight = @_cvs.height / 12
    energiesHeight = @_cvs.height - beatsHeight

    window = end - start
    pixelsPerSecond = @_cvs.width / window
    pixelsPerEnergy = energiesHeight / 2 / beatManager.getMaxEnergy()

    getX = (seconds) ->
      Math.round((seconds - start) * pixelsPerSecond)

    getY = (energy) ->
     Math.round(-energy * pixelsPerEnergy)


    # Maximum energies
    @_ctx.fillStyle = '#00bc34'
    for [i, energy] in beatManager.getEnergies()
      continue if i < start
      break if i > end
      @_ctx.fillRect(getX(i), energiesHeight, 1, getY(energy))

    # Average energies
    @_ctx.fillStyle = 'rgba(255, 0, 255, 0.5)'
    for [i, energy] in beatManager.getAverageEnergies()
      @_ctx.fillRect(getX(i), energiesHeight, 1, getY(energy))


    # Beats
    beatHeight = beatsHeight / 2
    @_ctx.fillStyle = '#ff9045'
    for beat in beatManager.getBeats()
      continue if beat < start
      break if beat > end
      @_ctx.fillRect(
        getX(beat),
        @_cvs.height - beatHeight * 2,
        1,
        beatHeight
      )

    # Interpolated beats
    @_ctx.fillStyle = '#0088ff'
    for beat in beatManager.getInterpolatedBeats()
      continue if beat < start
      break if beat > end
      height = Math.round(@_cvs.height / 12)
      @_ctx.fillRect(
        getX(beat),
        @_cvs.height - beatHeight * 2,
        1,
        beatHeight
      )

    # Principal beat
    @_ctx.fillStyle = '#ff0000'
    @_ctx.fillRect(
      getX(beatManager.getPrincipalBeatTime()),
      @_cvs.height - beatHeight * 2,
      1,
      beatHeight
    )

    # Maximum Energies
    @_ctx.fillStyle = '#222'
    for beat in beatManager.getMaximumEnergies()
      continue if beat < start
      break if beat > end
      @_ctx.fillRect(getX(beat), @_cvs.height - beatHeight, 1, beatHeight)

