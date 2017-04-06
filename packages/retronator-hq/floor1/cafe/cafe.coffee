LOI = LandsOfIllusions
HQ = Retronator.HQ
PAA = PixelArtAcademy

Vocabulary = LOI.Parser.Vocabulary

class HQ.Cafe extends LOI.Adventure.Location
  @id: -> 'Retronator.HQ.Cafe'
  @url: -> 'retronator/cafe'

  @version: -> '0.0.1'

  @fullName: -> "Retronator Café"
  @shortName: -> "café"
  @description: ->
    "
      The cosy café has plenty of tables and you recognize some familiar faces from the Pixel Art Academy Facebook
      group. The north wall displays a selection of artworks from the current featured pixel artist. In the south
      there is a self-serve bar and Burra's carefully decorated workstation. A passageway connects to the coworking space
      in the west, and there are big steps with stairs heading up to the store.
    "

  @listeners: ->
    super.concat [
      @BurraListener
    ]
  
  @initialize()

  constructor: ->
    super

    @loginButtonsSession = Accounts._loginButtonsSession

  things: -> [
    @constructor.Artworks
    PAA.Cast.Burra
  ]

  exits: ->
    "#{Vocabulary.Keys.Directions.Up}": HQ.Store
    "#{Vocabulary.Keys.Directions.West}": HQ.Coworking
    "#{Vocabulary.Keys.Directions.Out}": SanFrancisco.Soma.SecondStreet

  class @BurraListener extends LOI.Adventure.Listener
    @id: -> "Retronator.HQ.Cafe.Burra"

    @scriptUrls: -> [
      'retronator_retronator-hq/floor1/cafe/burra.script'
    ]

    class @Script extends LOI.Adventure.Script
      @id: -> "Retronator.HQ.Cafe.Burra"
      @initialize()

      initialize: ->
        @setCurrentThings burra: PAA.Cast.Burra

        @setCallbacks
          OpenRetronatorMagazine: (complete) =>
            medium = window.open 'https://medium.com/retronator-magazine', '_blank'
            medium.focus()

            # Wait for our window to get focus.
            $(window).on 'focus.medium', =>
              complete()
              $(window).off '.medium'

          ReceiveProspectus: (complete) =>
            HQ.Items.Prospectus.state 'inInventory', true
            complete()

    @initialize()

    startScript: (options) ->
      LOI.adventure.director.startScript @script, options

    onScriptsLoaded: ->
      @script = @scripts[@constructor.Script.id()]

    onCommand: (commandResponse) ->
      return unless burra = LOI.adventure.getCurrentThing PAA.Cast.Burra
      @script.setThings {burra}

      commandResponse.onPhrase
        form: [Vocabulary.Keys.Verbs.TalkTo, burra.avatar]
        action: => LOI.adventure.director.startScript @script

    onEnter: (enterResponse) ->

    onExitAttempt: (exitResponse) ->
      
    onExit: (exitResponse) ->
      
    cleanup: ->