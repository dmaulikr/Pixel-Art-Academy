AB = Artificial.Babel
AM = Artificial.Mirage
LOI = LandsOfIllusions

# Command response captures the listener's response to a command. It contains all the information for the UI to provide
# feedback to the player in case the command is ambiguous or the conditions for its execution are not met.
class LOI.Parser.CommandResponse
  @MatchingModes:
    Exact: 'Exact'
    Includes: 'Includes'

  constructor: (@options) ->
    @matchingPhraseActions = []

  # Register an action that happens when the given phrase (or any of the aliases) is present somewhere in the command.
  onPhrase: (phraseAction) ->
    @matchingPhraseActions.push
      phraseAction: phraseAction
      matchingMode: @constructor.MatchingModes.Includes

  # Register an action that happens when the command is exactly the given phrase (or any of the aliases).
  onExactPhrase: (phraseAction) ->
    @matchingPhraseActions.push
      phraseAction: phraseAction
      matchingMode: @constructor.MatchingModes.Exact

  generateActions: ->
    likelyActions = for matchingPhraseAction in @matchingPhraseActions
      phraseAction = matchingPhraseAction.phraseAction
      matchingMode = matchingPhraseAction.matchingMode

      likelihood = 1

      # Phrase is composed out of a sequence of parts. Each part can have an array
      # of aliases, so first we generate all the permutations of the form.
      form = phraseAction.form.slice 0

      # Wrap any single alternatives into arrays as well.
      for formPart, i in form
        form[i] = [formPart] unless _.isArray formPart

      # Expand keys and avatars into translated strings.
      for formPart, i in form
        translatedStrings = for alias in formPart
          if _.isString alias
            # We have a phrase key.
            phraseKey = alias
            @options.parser.vocabulary.getPhrases phraseKey

          else if alias instanceof LOI.Avatar
            # We have an avatar.
            avatar = alias

            # We create all possible name phrase sequences out of the short and full name.
            normalizeAvatarName = (name) -> _.toLower _.deburr name

            shortNamePhrases = AB.Helpers.generatePhrases text: normalizeAvatarName avatar.shortName()
            fullNamePhrases = AB.Helpers.generatePhrases text: normalizeAvatarName avatar.fullName()

            _.union shortNamePhrases, fullNamePhrases

          else
            console.error "Unknown phrase form part.", alias
            null

        form[i] = _.flatten translatedStrings

      # Create all possible combinations of the form. The total number
      # of combinations is the product of alternative counts.
      combinationsCount = 1
      combinationsCount *= formPart.length for formPart in form

      # We need to analyze the form. We want to know, for each part, how many combinations are possible out of the
      # parts before and after each of the parts. Out of these numbers we calculate how many times we need to repeat
      # each alias in the big array of combinations.
      before = 1
      after = combinationsCount

      partInfo = []

      for formPart, i in form
        after /= formPart.length

        partInfo[i] =
          repeat: before
          aliasesCount: formPart.length
          iterate: after
          blockSize: formPart.length * after

        before *= formPart.length

      formCombinations = []

      for aliases, formPartIndex in form
        info = partInfo[formPartIndex]

        for i in [0...info.repeat]
          for alias, aliasIndex in aliases
            for j in [0...info.iterate]
              combinationIndex = i * info.blockSize + aliasIndex * info.iterate + j
              formCombinations[combinationIndex] ?= []
              formCombinations[combinationIndex][formPartIndex] = alias

      console.log "Form combinations", (combination.join ' ' for combination in formCombinations) if LOI.debug

      likelihoodCache = {}
      commandWords = _.words @options.command.normalizedCommand

      for combinationPhrases in formCombinations
        # Calculate likelihood of desired phrases being present in the command.
        likelihood = 1

        switch matchingMode
          when @constructor.MatchingModes.Exact
            translatedPhrase = combinationPhrases.join ' '

            if likelihoodCache[translatedPhrase]
              likelihood = likelihoodCache[translatedPhrase]

            else
              likelihood = @options.command.is translatedPhrase
              likelihoodCache[translatedPhrase] = likelihood

          when @constructor.MatchingModes.Includes
            for translatedPhrase in combinationPhrases
              phraseLikelihood = 0

              # See if we've already calculated this phrase's likelihood.
              if likelihoodCache[translatedPhrase]
                phraseLikelihood = likelihoodCache[translatedPhrase]

              else
                # Calculate how likely this phrase is in the command.
                phraseLikelihood = @options.command.has translatedPhrase
                likelihoodCache[translatedPhrase] = phraseLikelihood

              likelihood *= phraseLikelihood

        console.log "For phrase", combinationPhrases.join(' '), "likelihood in mode", matchingMode, "is", likelihood if LOI.debug

        # We also calculate precision, how closely the phrase has matched the command.
        targetWords = _.words combinationPhrases.join '_'

        differenceA = _.difference targetWords, commandWords
        differenceB = _.difference commandWords, targetWords

        precision = 1 - (differenceA.length + differenceB.length) / commandWords.length

        # Priority is another ordering mechanism, one provided by the listener,
        # for example, when overriding a generic response with a custom one.
        priority = phraseAction.priority or 0

        # Return an action with the likelihood that this is what the user wanted.
        phraseAction: phraseAction
        likelihood: likelihood
        precision: precision
        priority: priority
        translatedForm: combinationPhrases

    # Likely actions include nested arrays for all actions so we return a flattened version.
    _.flattenDeep likelyActions
