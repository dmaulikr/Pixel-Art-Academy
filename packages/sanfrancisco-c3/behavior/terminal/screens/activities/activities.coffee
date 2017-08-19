AM = Artificial.Mirage
AMu = Artificial.Mummification
LOI = LandsOfIllusions
C3 = SanFrancisco.C3

Activity = LOI.Character.Behavior.Activity

class C3.Behavior.Terminal.Activities extends AM.Component
  @register 'SanFrancisco.C3.Behavior.Terminal.Activities'

  constructor: (@terminal) ->
    super

    @property = new ReactiveField null

    # We use this when the user wants to choose a different template (and templates wouldn't be shown by default).
    @forceShowTemplates = new ReactiveField false

    # We use this when the user wants to customize the options.
    @forceShowEditor = new ReactiveField false

  onCreated: ->
    super

    # Get the activities part from the character.
    @autorun (computation) =>
      behaviorPart = @terminal.screens.character.character()?.behavior.part
      activitiesProperty = behaviorPart.properties.activities

      @property activitiesProperty

    @hasCustomData = new ComputedField =>
      @property()?.options.dataLocation()?.data()

    @showTemplates = new ComputedField =>
      return true if @forceShowTemplates()
      return false if @forceShowEditor()

      # We default to showing available templates if the part hasn't been set yet.
      not @hasCustomData()

    # Subscribe to activities templates.
    LOI.Character.Part.Template.forType.subscribe @, LOI.Character.Part.Types.Behavior.options.properties.activities.options.templateType

    @templateNameInput = new LOI.Components.TranslationInput
      placeholderText: => @translation "Name the template"

    @templateDescriptionInput = new LOI.Components.TranslationInput
      placeholderText: => @translation "Describe the activities selection"

  renderTemplateNameInput: ->
    @templateNameInput.renderComponent @currentComponent()

  renderTemplateDescriptionInput: ->
    @templateDescriptionInput.renderComponent @currentComponent()

  templates: ->
    LOI.Character.Part.Template.documents.find
      type: LOI.Character.Part.Types.Behavior.options.properties.activities.options.templateType

  templateParts: ->
    template = @currentData()
    property = @property()

    dataField = AMu.Hierarchy.create
      templateClass: LOI.Character.Part.Template
      load: => template

    property.create
      dataLocation: new AMu.Hierarchy.Location
        rootField: dataField

  # Note that we can't name this helper 'template' since that would override Blaze Component template method.
  partsTemplate: ->
    @property()?.options.dataLocation()?.template

  isOwnPartsTemplate: ->
    userId = Meteor.userId()
    template = @partsTemplate()
    template.author._id is userId

  backButtonCallback: ->
    @closeScreen()

    # Instruct the back button to cancel closing (so it doesn't disappear).
    cancel: true

  closeScreen: ->
    if @forceShowTemplates()
      # We only need to not show templates in this case.
      @forceShowTemplates false

    else
      # We return back to the character screen.
      @terminal.switchToScreen @terminal.screens.character

  activities: ->
    # Start with the default activities.
    activities =
      "#{Activity.Keys.Sleep}":
        nameEditable: false
        hoursPerWeek: 0

      "#{Activity.Keys.Job}":
        nameEditable: false
        hoursPerWeek: 0

      "#{Activity.Keys.School}":
        nameEditable: false
        hoursPerWeek: 0

      "#{Activity.Keys.Drawing}":
        nameEditable: false
        hoursPerWeek: 0

    # Add all character's focal points.
    for activityPart in @property().parts()
      activityKey = activityPart.properties.key.options.dataLocation()
      activityHoursPerWeek = activityPart.properties.hoursPerWeek.options.dataLocation()

      unless activities[activityKey]
        activities[activityKey] = nameEditable: true

      activities[activityKey].part = activityPart
      activities[activityKey].hoursPerWeek = activityHoursPerWeek

    # Return an array.
    for activityName, activity of activities
      _.extend {}, activity, key: activityName

  hoursSleep: ->
    # Find sleep focal point.
    sleepActivity = _.find @property().parts(), (activityPart) =>
      activityName = activityPart.properties.key.options.dataLocation()
      activityName is Activity.Keys.Sleep

    sleepActivity?.properties.hoursPerWeek.options.dataLocation() or 0

  hoursAfterSleep: ->
    24 * 7 - @hoursSleep()

  hoursJobSchool: ->
    total = 0

    # Find job and sleep focal points.
    for activityName in [Activity.Keys.Job, Activity.Keys.School]
      activity = _.find @property().parts(), (activityPart) =>
        activityPart.properties.key.options.dataLocation() is activityName

      total += activity?.properties.hoursPerWeek.options.dataLocation() or 0

    total

  hoursAfterJobSchool: ->
    @hoursAfterSleep() - @hoursJobSchool()

  hoursActivities: ->
    total = 0

    for activityPart in @property().parts()
      activityKey = activityPart.properties.key.options.dataLocation()

      continue if activityKey in [Activity.Keys.Job, Activity.Keys.School, Activity.Keys.Sleep]

      total += activityPart.properties.hoursPerWeek.options.dataLocation()

    total

  extraHoursPerWeek: ->
    @hoursAfterJobSchool() - @hoursActivities()

  extraHoursPerDay: ->
    Math.round(@extraHoursPerWeek() / 0.7) / 10

  extraHoursTooLow: ->
    @extraHoursPerWeek() < 20

  extraHoursTooHigh: ->
    @extraHoursPerWeek() > 50

  events: ->
    super.concat
      'click .done-button': @onClickDoneButton
      'click .replace-button': @onClickReplaceButton
      'click .save-as-template-button': @onClickSaveAsTemplateButton
      'click .unlink-template-button': @onClickUnlinkTemplateButton
      'click .custom-activities-button': @onClickCustomActivitiesButton
      'click .delete-button': @onClickDeleteButton
      'click .template': @onClickTemplate
      'change .new-activity': @onChangeNewActivity

  onClickDoneButton: (event) ->
    @closeScreen()

  onClickReplaceButton: (event) ->
    @forceShowTemplates true
    @forceShowEditor false

  onClickSaveAsTemplateButton: (event) ->
    @property()?.options.dataLocation.createTemplate()

  onClickUnlinkTemplateButton: (event) ->
    @property()?.options.dataLocation.unlinkTemplate()

  onClickCustomActivitiesButton: (event) ->
    # Delete current data at this node.
    @property()?.options.dataLocation.clear()

    @forceShowEditor true
    @forceShowTemplates false

  onClickDeleteButton: (event) ->
    # Delete current data at this node.
    @property()?.options.dataLocation.remove()

    # Pop this part off the stack.
    @popPart()

  onClickTemplate: (event) ->
    template = @currentData()

    @property()?.options.dataLocation.setTemplate template._id

    @forceShowTemplates false

    # Return to previous item where we will see the result of choosing this part.
    @closeScreen()

  onChangeNewActivity: (event) ->
    $input = $(event.target)
    name = $input.val()
    return unless name.length

    # Clear input for next entry.
    $input.val('')

    activityType = LOI.Character.Part.Types.Behavior.Activity.options.type
    newPart = @property().newPart activityType

    newPart.options.dataLocation
      key: name
      hoursPerWeek: 0

  # Components

  class @ActivityHoursPerWeek extends AM.DataInputComponent
    @register 'SanFrancisco.C3.Behavior.Terminal.Character.ActivityHoursPerWeek'

    constructor: ->
      super

      @type = AM.DataInputComponent.Types.Number
      @placeholder = 0
      @customAttributes =
        min: 0
        step: 1

    load: ->
      activityInfo = @data()
      activityInfo.hoursPerWeek

    save: (value) ->
      activityInfo = @data()

      if activityInfo.part
        part = activityInfo.part
        part.properties.hoursPerWeek.options.dataLocation value * @_saveFactor()

      else
        characterComponent = @ancestorComponentOfType C3.Behavior.Terminal.Character

        activityType = LOI.Character.Part.Types.Behavior.Activity.options.type
        newPart = characterComponent.character().behavior.part.properties.activities.newPart activityType

        newPart.options.dataLocation
          key: activityInfo.key
          hoursPerWeek: value * @_saveFactor()

    _saveFactor: ->
      1

  class @ActivityHoursPerDay extends @ActivityHoursPerWeek
    @register 'SanFrancisco.C3.Behavior.Terminal.Character.ActivityHoursPerDay'

    load: ->
      activityInfo = @data()
      Math.round(activityInfo.hoursPerWeek / 0.7) / 10

    _saveFactor: ->
      7

  class @ActivityName extends AM.DataInputComponent
    @register 'SanFrancisco.C3.Behavior.Terminal.Character.ActivityName'

    load: ->
      activityInfo = @data()
      activityInfo.key

      # TODO: Get translation for key.

    save: (value) ->
      activityInfo = @data()

      if value.length
        # Update focal point name.
        activityInfo.part.properties.key.options.dataLocation value

      else
        # Delete focal point.
        activityInfo.part.options.dataLocation.remove()