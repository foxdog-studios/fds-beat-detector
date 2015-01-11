class BeatDetector.BeatFlash
  constructor: (@_cvs) ->
    @_ctx = @_cvs.getContext '2d'
    @_cvs.width = $(@_cvs).width()

  render: (timeOut) ->
    if @_handle?
      Meteor.clearTimeout @_handle
    @_ctx.fillStyle = '#04f771'
    @_ctx.fillRect(0, 0, @_cvs.width, @_cvs.height)
    @_handle = Meteor.setTimeout =>
      @_cvs.width = @_cvs.width
      @_handle = null
    , timeOut

