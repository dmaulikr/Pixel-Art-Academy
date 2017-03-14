AC = Artificial.Control
LOI = LandsOfIllusions
C1 = PixelArtAcademy.Season1.Episode0.Chapter1
RS = Retropolis.Spaceport

class C1.Start.Terrace extends LOI.Adventure.Scene
  @id: -> 'PixelArtAcademy.Season1.Episode0.Chapter1.Start.Terrace'

  @location: -> RS.AirportTerminal.Terrace

  @translations: ->
    intro: "
      You exit the Retropolis International Spaceport.
      A magnificent view of the city opens before you and you feel the adventure in the air.
      The terrace you're standing on connects back to the airport terminal in the south.
    "

  @initialize()

  things: ->
    [
      C1.Items.Backpack unless C1.Items.Backpack.state 'inInventory'
      C1.Actors.Alex if @state 'alexPresent'
    ]

  @defaultScriptUrl: -> 'retronator_pixelartacademy-season1-episode0/chapter1/sections/start/scenes/terrace.script'

  onEnter: (enterResponse) ->
    scene = @options.parent

    # Provide the introduction text the first time we enter.
    introductionDone = scene.state 'introductionDone'

    unless introductionDone
      enterResponse.overrideIntroduction =>
        scene.translations()?.intro

      scene.state 'introductionDone', true

    # Alex should enter after 30s unless they are already present or they have already talked to you.
    unless scene.state('alexPresent') or C1.Actors.Alex.state('firstTalkDone')
      # But wait first that the interface and time is ready.
      @autorun (computation) =>
        return unless LOI.adventure.interface.uiInView()
        return unless time = LOI.adventure.time()
        computation.stop()
        
        @_alexEntersTimeout = Meteor.setTimeout =>
          @startScript label: "AlexEnters"
        ,
          30000
        
        # Also record the adventure time so we have our 10 min countdown for airship departure.
        scene.section.chapter.state 'startTime', time

    # Alex should talk when at location.
    @_alexTalksAutorun = @autorun (computation) =>
      return unless scene.state('alexPresent')

      return unless @scriptsReady()
      return unless alex = LOI.adventure.getCurrentThing C1.Actors.Alex
      return unless alex.ready()
      computation.stop()

      @script.setThings {alex}

      @startScript label: "AlexIsPresent"

  onExitAttempt: (exitResponse) ->
    # We need the backpack before we can leave.
    hasBackpack = C1.Items.Backpack.state 'inInventory'
    unless hasBackpack
      @startScript label: 'LeaveWithoutBackpack'
      exitResponse.preventExit()
      return

    # We have the backpack, but don't leave just yet, we'll do the title animation, unless it already ran (this method
    # will be called the second time around when animation has finished, so we need to let it through at that time).
    return if @_titleAnimationStarted

    @_titleAnimationStarted = true
    exitResponse.preventExit()

    scene = @options.parent
    scene._animateTitle()

  _animateTitle: ->
    LOI.adventure.addModalDialog @
    @cleanup()

    # Skip animation on enter.
    $(document).on 'keydown.startSection', (event) =>
      # Only process keys if we're the top-most dialog.
      return unless LOI.adventure.modalDialogs()[0] is @

      keyCode = event.which
      @_showChapterTitle() if keyCode is AC.Keys.enter or keyCode is AC.Keys.escape

    # Fade out UI
    $('.ui').velocity
      opacity: [0, 1]
    ,
      duration: 1000

    # Scroll full scene into view after a delay so that the narrative has finished scrolling.
    Meteor.setTimeout =>
      # We need to scroll so that the title section is in view.
      position = parseInt $('.title-section').css 'top'

      LOI.adventure.interface.scroll
        position: position
        animate: true
        easing: 'ease-in-out'
        duration: 5000
    ,
      1000

    # Fade in title.
    $('.landing-page .title-section .middle').velocity
      opacity: 1
    ,
      delay: 5000
      duration: 2000
      easing: 'ease-in-out'
      complete: =>
        $('.landing-page .title-section .top').velocity
          opacity: 1
        ,
          duration: 2000
          delay: 1000
          easing: 'ease-in-out'
          complete: =>
            Meteor.setTimeout =>
              @_showChapterTitle()
            ,
              3000

  _showChapterTitle: ->
    # Only allow one call to this.
    return if @_chapterTitleShown
    @_chapterTitleShown = true

    @section.chapter.showChapterTitle
      onActivated: =>
        # Mark the section goal condition.
        @section.state 'leftTerrace', true

        # Set the whole game as started.
        gameState = LOI.adventure.gameState()
        gameState.gameStarted = true
        LOI.adventure.gameState.updated()

        # Move on to Concourse.
        LOI.adventure.goToLocation RS.AirportTerminal.Concourse

        # Clean up.
        $(document).off '.startSection'
        LOI.adventure.removeModalDialog @
        $('.ui').velocity('stop').css opacity: 1

  cleanup: ->
    super

    # Stop Alex's timer.
    Meteor.clearTimeout @_alexEntersTimeout

    @_alexTalksAutorun?.stop()
