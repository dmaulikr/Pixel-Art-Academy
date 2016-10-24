LOI = LandsOfIllusions

class LOI.Adventure.Director
  constructor: (@location) ->
    @currentScripts = new ReactiveField []

  onCreated: ->
    super

    @autorun =>
      console.log "got new scrips", @currentScripts()

  startScript: (script) ->
    script.setDirector @

    @scriptTransition null, script.startNode

  endScript: (scriptNode) ->
    @scriptTransition scriptNode, null

  scriptTransition: (currentScriptNode, nextScriptNode) ->
    scriptNodes = @currentScripts()

    # Give out warnings if nodes don't exist or are already present.
    console.warn "Node to be transitioned from is not active.", currentScriptNode if currentScriptNode and not (currentScriptNode in scriptNodes)
    console.warn "Node to be transitioned to is already active.", nextScriptNode if nextScriptNode in scriptNodes

    # Remove current script node.
    scriptNodes = _.without scriptNodes, currentScriptNode if currentScriptNode

    # Add new script node.
    scriptNodes = _.union scriptNodes, [nextScriptNode] if nextScriptNode

    # Trigger update of running scripts.
    @currentScripts scriptNodes
