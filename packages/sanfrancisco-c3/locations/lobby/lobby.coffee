LOI = LandsOfIllusions

Vocabulary = LOI.Parser.Vocabulary

class LOI.Construct.Locations.C3.Lobby extends LOI.Construct.Location
  @id: -> 'LandsOfIllusions.Construct.Locations.C3.Lobby'
  @url: -> 'c3/lobby'
  @scriptUrls: -> super.concat [
  ]

  @version: -> '0.0.1'

  @fullName: -> "Character Construction Center lobby"
  @shortName: -> "lobby"
  @description: ->
    "
      The lobby of the Character Construction Center, or C3 for short, is spacious and emits a high-tec vibe.
      Scientists in their white coats walk around with determination.
      Two main hallways lead to Design Control northwest and the Stasis Chamber northeast.
    "

  @initialize()

  constructor: ->
    super

  destroy: ->
    super

  @state: ->
    things = {}

    exits = {}
    exits[Vocabulary.Keys.Directions.South] = LOI.Construct.Locations.C3.Entrance.id()
    exits[Vocabulary.Keys.Directions.Out] = LOI.Construct.Locations.C3.Entrance.id()

    _.merge {}, super,
      things: things
      exits: exits