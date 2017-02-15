LOI = LandsOfIllusions
PAA = PixelArtAcademy
RS = Retropolis.Spaceport

Vocabulary = LOI.Parser.Vocabulary
Verbs = Vocabulary.Keys.Verbs

class RS.AirportTerminal.Terrace.VendingMachine extends LOI.Adventure.Item
  @id: -> 'Retropolis.Spaceport.AirshipTerminal.Terrace.VendingMachine'
  @fullName: -> "vending machine"
  @nameAutoCorrectStyle: -> LOI.Avatar.NameAutoCorrectStyle.FullName
  @description: ->
    "
      It seems to dispense beverages.
    "
  @color: ->
    hue: LOI.Assets.Palette.Atari2600.hues.cyan
    shade: LOI.Assets.Palette.Atari2600.characterShades.normal

  @dialogDeliveryType: -> LOI.Avatar.DialogDeliveryType.Displaying
  @dialogTextTransform: -> LOI.Avatar.DialogTextTransform.Uppercase

  @initialize()

  @listeners: -> [
    @Listener
  ]

  class @Listener extends LOI.Adventure.Listener
    @scriptUrls: -> [
      'retronator_retropolis-spaceport/airportterminal/concourse/terrace/vendingmachine.script'
    ]

    class @Script extends LOI.Adventure.Script
      @id: -> 'Retropolis.Spaceport.AirshipTerminal.Terrace.VendingMachine'
      @initialize()

      initialize: ->
        machine = @options.parent

        @setActors {machine}

        @setCallbacks
          PrepareDrink: (complete) =>
            drinkType = @ephemeralState 'drinkType'
            drink = PAA.Items.Bottle.createDrink drinkType

            @ephemeralState 'drink', drink

            complete()

          ReceiveBottle: (complete) =>
            drinkType = @ephemeralState 'drinkType'

            PAA.Items.Bottle.state 'drinkType', drinkType
            PAA.Items.Bottle.state 'inInventory', true

            complete()

          ReturnBottle: (complete) =>
            PAA.Items.Bottle.state 'inInventory', false
            complete()

    @initialize()

    onCommand: (commandResponse) ->
      machine = @options.parent

      commandResponse.onPhrase
        form: [Vocabulary.Keys.Verbs.Use, machine.avatar]
        action: =>
          LOI.adventure.director.startScript @scripts[@constructor.Script.id()]

      bottle = LOI.adventure.getCurrentThing PAA.Items.Bottle
      
      if bottle
        commandResponse.onPhrase
          form: [Vocabulary.Keys.Verbs.Return, bottle.avatar]
          action: => @_returnBottle()

        commandResponse.onPhrase
          form: [[Verbs.ReturnTo, Verbs.GiveTo, Verbs.UseWith, Verbs.UseIn], bottle.avatar, machine.avatar]
          action: => @_returnBottle()

    _returnBottle: ->
      LOI.adventure.director.startScript @scripts[@constructor.Script.id()], label: 'ReturnBottle'