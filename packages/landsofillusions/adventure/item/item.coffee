AM = Artificial.Mirage
LOI = LandsOfIllusions

class LOI.Adventure.Item extends LOI.Adventure.Thing
  # Static location properties and methods

  @activatedStates:
    Deactivated: 'Deactivated'
    Activating: 'Activating'
    Activated: 'Activated'
    Deactivating: 'Deactivating'

  # Items with multiple copies
  
  @createCopy: (options = {}) ->
    copyId = Random.id()
    copyStateAddress = @stateAddress.child "copies.#{copyId}"

    copy = new @
      stateAddress: copyStateAddress

    copy.state 'timelineId', options.timelineId if options.timelineId

    copy

  @getCopies: (options = {}) ->
    copies = @state 'copies'

    copyInstances = for copyId of copies
      new @
        stateAddress: @stateAddress.child "copies.#{copyId}"

    if options.timelineId
      copyInstances = _.filter copyInstances, (copy) -> copy.state('timelineId') is options.timelineId

    copyInstances

  # Item instance
    
  # Tells if the item supports the activate interaction.
  isActivatable: -> false

  constructor: (@options) ->
    super
    
    # An item that can be activated has 4 stages in its lifecycle. You can use this
    # as a reactive variable to depend on the state the item is currently in.
    @activatedState = new ReactiveField @constructor.activatedStates.Deactivated

    # Override state address if it was provided (used with copies).
    if @options?.stateAddress
      @stateAddress = @options.stateAddress
      @state = new LOI.StateObject address: @stateAddress

  deactivated: -> @activatedState() is @constructor.activatedStates.Deactivated
  activating: -> @activatedState() is @constructor.activatedStates.Activating
  activated: -> @activatedState() is @constructor.activatedStates.Activated
  deactivating: -> @activatedState() is @constructor.activatedStates.Deactivating

  activate: (onActivatedCallback) ->
    # The item gets activated (used).
    @activatedState @constructor.activatedStates.Activating

    @onActivate =>
      @activatedState @constructor.activatedStates.Activated
      onActivatedCallback?()

  deactivate: (onDeactivatedCallback) ->
    # The item gets deactivated.
    @activatedState @constructor.activatedStates.Deactivating

    @onDeactivate =>
      @activatedState @constructor.activatedStates.Deactivated
      onDeactivatedCallback?()

  # Handlers

  onActivate: (finishedActivatingCallback) ->
    # Override to perform any logic when item is activated. Report that you've done the necessary
    # steps by calling the provided callback. By default we just call the callback straight away.
    finishedActivatingCallback()

  onDeactivate: (finishedDeactivatingCallback) ->
    # Override to perform any logic when item is about to be deactivated. Report that you've done the
    # necessary steps by calling the provided callback. By default we just call the callback straight away.
    finishedDeactivatingCallback()
