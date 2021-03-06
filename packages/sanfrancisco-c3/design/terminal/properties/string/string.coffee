AM = Artificial.Mirage
LOI = LandsOfIllusions
C3 = SanFrancisco.C3

class C3.Design.Terminal.Properties.String extends AM.Component
  @register 'SanFrancisco.C3.Design.Terminal.Properties.String'

  onCreated: ->
    super

    property = @data()
    @input = new @constructor.Input property.options.dataLocation

  class @Input extends AM.DataInputComponent
    constructor: (@dataLocation) ->
      super

    load: ->
      @dataLocation()

    save: (value) ->
      @dataLocation value
