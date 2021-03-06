LOI = LandsOfIllusions
HQ = Retronator.HQ

Vocabulary = LOI.Parser.Vocabulary

class HQ.Elevator extends LOI.Adventure.Location
  @id: -> 'Retronator.HQ.Elevator'
  @url: -> 'retronator/lobby/elevator'
  @region: -> HQ

  @version: -> '0.0.1'

  @fullName: -> "Retronator HQ elevator"
  @shortName: -> "elevator"
  @description: ->
    "
      You are in the elevator of Retronator HQ. The number pad on the side lets you travel to different floors.
    "

  @initialize()

  @floor: ->
    return unless LOI.adventureInitialized() and LOI.adventure.gameState()

    floor = @state 'floor'

    # Set floor to 1 by default.
    unless floor
      floor = 1
      @state 'floor', floor

    floor

  things: -> [
    HQ.Elevator.NumberPad
  ]

  exits: ->
    # We register dependency on elevator floor.
    floor = @constructor.floor()

    switch floor
      when 6 then exitLocation = HQ.Residence.UpstairsHallway
      when 5 then exitLocation = HQ.Residence.Hallway
      when 4 then exitLocation = HQ.ArtStudio
      when 3 then exitLocation = HQ.GalleryWest
      when 2 then exitLocation = HQ.Store
      when 1 then exitLocation = HQ.Coworking
      when -1 then exitLocation = HQ.Basement

    exits = {}

    if exitLocation
      exits[Vocabulary.Keys.Directions.North] = exitLocation
      exits[Vocabulary.Keys.Directions.Out] = exitLocation

    exits

  @addElevatorExit: (options, exits) ->
    # See if elevator floor is the same as the location floor.
    elevatorFloor = HQ.Elevator.floor()
    locationFloor = options.floor

    return exits unless elevatorFloor is locationFloor

    # Add the south exit to exits.
    _.extend exits,
      "#{Vocabulary.Keys.Directions.South}": HQ.Elevator
      "#{Vocabulary.Keys.Directions.In}": HQ.Elevator
