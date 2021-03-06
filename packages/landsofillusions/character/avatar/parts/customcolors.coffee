LOI = LandsOfIllusions

class LOI.Character.Avatar.Parts.CustomColors extends LOI.Character.Part
  createRenderer: (engineOptions, options = {}) ->
    existingMaterialData = options.materialsData

    # Add custom colors.
    options.materialsData = new ComputedField =>
      # We have to clone existing material data because the parent sends the same object to multiple parts.
      materialsData = _.extend {}, existingMaterialData?()

      customColorsType = LOI.Character.Part.Types.Avatar.Outfit.CustomColor.options.type
      customColorsProperty = _.find @properties, (property) => property.options.type is customColorsType

      return unless customColorsFields = customColorsProperty.options.dataLocation()?.data()?.fields

      for customColorOrder, customColor of customColorsFields when customColor.node
        nameField = customColor.node.fields.name
        colorField = customColor.node.fields.color

        continue unless nameField?.value and colorField

        materialsData[nameField.value] =
          ramp: colorField.node.fields.hue?.value
          shade: colorField.node.fields.shade?.value

      materialsData

    super engineOptions, options
