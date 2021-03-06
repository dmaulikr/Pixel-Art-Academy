AC = Artificial.Control
LOI = LandsOfIllusions

class LOI.Assets.SpriteEditor.Tools.ColorPicker extends LandsOfIllusions.Assets.Tools.Tool
  constructor: ->
    super

    @name = "Color picker"
    @shortcut = AC.Keys.c
    @holdShortcut = AC.Keys.alt

  onMouseDown: (event) ->
    super

    @pickColor()

  onMouseMove: (event) ->
    super

    @pickColor()

  pickColor: ->
    return unless @mouseState.leftButton

    spriteData = @options.editor().spriteData()

    # Go over all pixels to find the one we want.
    for layer in spriteData.layers
      for pixel in layer.pixels
        if pixel.x is @mouseState.x and pixel.y is @mouseState.y
          if pixel.paletteColor
            @options.editor().palette().setColor pixel.paletteColor.ramp, pixel.paletteColor.shade
            
          else if pixel.materialIndex?
            @options.editor().materials().setIndex pixel.materialIndex

          if pixel.normal
            @options.editor().shadingSphere().setNormal pixel.normal

          return
