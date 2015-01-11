class BeatDetector.Visualisation
  constructor: (@_parentElement, @_audioContext) ->
    $(@_parentElement).addClass 'beat-detector-visualisation'
    @_beatFlashCanvas = document.createElement 'canvas'
    @_beatDetectorCanvas = document.createElement 'canvas'
    @_timelineCanvas = document.createElement 'canvas'
    for el in [@_beatFlashCanvas, @_beatDetectorCanvas, @_timelineCanvas]
      @_parentElement.appendChild el
      $(el).addClass 'beat-detector-visualisation-layer'
    @_beatFlash = new BeatDetector.BeatFlash @_beatFlashCanvas
    @_timeline = new BeatDetector.Timeline @_timelineCanvas
    @_beatDetectorVisualisation = \
      new BeatDetector.BeatDetectorVisualisation @_beatDetectorCanvas
    @_clickTrackPlayer = new BeatDetector.ClickTrackPlayer(
      @_audioContext,
      @_timeline,
      @_beatFlash
    )

  getClickTrackPlayer: ->
    @_clickTrackPlayer

  render: (beatManager) ->
    @_beatDetectorVisualisation.render(
      beatManager,
      0,
      beatManager.getTrackLengthSeconds()
    )

