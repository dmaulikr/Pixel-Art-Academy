LOI = LandsOfIllusions

class LOI.Character.Avatar.Renderers.BodyPart extends LOI.Character.Avatar.Renderers.Renderer
  constructor: ->
    super

    # Prepare renderer only when it has been created with engine options passed in.
    return unless @engineOptions

    @renderers = []
    @_createRenderers()

    @landmarks = new ComputedField =>
      # Create landmarks and update renderer translations.
      @_landmarks = {}

      # We start with the origin landmark.
      @_landmarks[@options.origin.landmark] =
        x: @options.origin.x or 0
        y: @options.origin.y or 0
        
      @_placeRenderers()

      @_landmarks

  _addLandmarks: (renderer) ->
    # Add all landmarks from this renderer.
    for rendererLandmarkName, rendererLandmark of renderer.landmarks()
      translatedLandmark = _.extend {}, rendererLandmark,
        x: rendererLandmark.x + renderer._translation.x
        y: rendererLandmark.y + renderer._translation.y

      @_landmarks[rendererLandmarkName] = translatedLandmark

  _placeRenderer: (renderer, rendererLandmarkName, landmarkName) ->
    rendererLandmarks = renderer.landmarks()
    return unless @_landmarks[landmarkName] and rendererLandmarks?[rendererLandmarkName]

    renderer._translation =
      x: @_landmarks[landmarkName].x - rendererLandmarks[rendererLandmarkName].x
      y: @_landmarks[landmarkName].y - rendererLandmarks[rendererLandmarkName].y

    @_addLandmarks renderer

  _bodyPartType: (partName) ->
    LOI.Character.Part.Types.Avatar.Body[partName].options.type

  drawToContext: (context, options = {}) ->
    # Depend on landmarks to update when renderer translations change.
    @landmarks()

    for renderer in @renderers
      context.save()

      translation = _.defaults {}, renderer._translation,
        x: 0
        y: 0

      context.translate translation.x, translation.y

      if renderer._flipHorizontal
        context.scale -1, 1
        context.translate -1, 0

      renderer.drawToContext context
      context.restore()
