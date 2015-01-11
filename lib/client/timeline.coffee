class BeatDetector.Timeline
  constructor: (@_cvs) ->
    @_ctx = @_cvs.getContext '2d'
    @_cvs.width = $(@_cvs).width()

  render: (time, start, end) ->
    @_cvs.width = @_cvs.width
    if time < start or time > end
      return
    window = end - start
    xPixelsPerSecond = @_cvs.width / window
    xPixels = Math.round(xPixelsPerSecond * (time - start))
    # clear the canvas
    @_ctx.fillStyle = "#886666"
    @_ctx.fillRect(xPixels - 1, 0, 4, @_cvs.height)
    @_ctx.fillStyle = "#FF0000"
    @_ctx.fillRect(xPixels, 0, 2, @_cvs.height)

