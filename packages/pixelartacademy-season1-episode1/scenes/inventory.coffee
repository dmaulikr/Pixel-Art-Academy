LOI = LandsOfIllusions
PAA = PixelArtAcademy
E1 = PixelArtAcademy.Season1.Episode1
HQ = Retronator.HQ

class E1.Inventory extends LOI.Adventure.Scene
  @id: -> 'PixelArtAcademy.Season1.Episode1.Inventory'

  @location: -> LOI.Adventure.Inventory

  @initialize()

  constructor: ->
    super

  things: ->
    [
      HQ.Items.OperatorLink
    ]
