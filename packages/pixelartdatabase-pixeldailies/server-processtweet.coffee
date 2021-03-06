AB = Artificial.Babel
AT = Artificial.Telepathy
PADB = PixelArtDatabase

class PADB.PixelDailies extends PADB.PixelDailies
  @processTweet: (tweet) ->
    if tweet.retweeted_status
      # This is a retweet, it's probably a submission! Check if we already have it.
      existing = @Submission.documents.findOne
        'tweetData.id': tweet.id

      # Only update favorites count if tweet exists without errors.
      if existing and not existing.processingError
        # See if the favorites count even is bigger.
        if existing.favoritesCount isnt tweet.retweeted_status.favorite_count
          @Submission.documents.update existing._id,
            $set:
              favoritesCount: tweet.retweeted_status.favorite_count

        return

      # If source tweet is truncated it will be missing images, so we have to fetch it from the source.
      if tweet.retweeted_status.truncated
        # The status might not exist anymore, which will throw an error from Twit, so we need to catch it.
        try
          tweet.retweeted_status = AT.Twitter.statusesShow
            id: tweet.retweeted_status.id_str
            tweet_mode: 'extended'

        catch e

      # Process (or reprocess) the tweet.
      submission =
        time: new Date tweet.retweeted_status.created_at
        text: tweet.retweeted_status.full_text or tweet.retweeted_status.text
        user:
          name: tweet.retweeted_status.user.name
          screenName: tweet.retweeted_status.user.screen_name
        favoritesCount: tweet.retweeted_status.favorite_count
        tweetData: tweet

      # Get tweet images.
      submission.images = []
      if tweet.retweeted_status.extended_entities?.media
        for media in tweet.retweeted_status.extended_entities.media
          switch media.type
            when 'photo'
              submission.tweetUrl ?= media.url
              submission.images.push
                imageUrl: media.media_url_https

            when 'animated_gif'
              submission.tweetUrl ?= media.url
              submission.images.push
                animated: true
                imageUrl: media.media_url_https
                videoUrl: media.video_info.variants[0].url

      if submission.images.length
        # Find the closest theme based on the hashtags.
        theme = @_findThemeForTweet tweet.retweeted_status

        if theme
          submission.theme =
            _id: theme._id

        else
          # We couldn't find any theme that would make sense, so flag the error.
          submission.processingError = @Submission.ProcessingError.NoThemeMatch

      else
        submission.processingError = @Submission.ProcessingError.NoImages

      # Insert the processed submission into the database.
      @Submission.documents.upsert 'tweetData.id': tweet.id, submission

      # Write the submission to PADB.
      @archiveSubmission submission

    else
      # This is a tweet directly from @Pixel_Dailes so it's likely a
      # theme, but do not process a tweet if it was already inserted.
      existing = @Theme.documents.findOne
        'tweetData.id': tweet.id

      return if existing

      # Prepare new theme document parameters.
      theme =
        time: new Date tweet.created_at
        text: tweet.full_text or tweet.text
        tweetData: tweet

      # The theme tweets must have a #pixel_dailies and another tag, which is the theme tag.
      hashtags = for hashtag in tweet.entities.hashtags
        hashtag.text.toLowerCase()

      if _.includes hashtags, 'pixel_dailies'
        themeHashtags = _.without hashtags, 'pixel_dailies', 'pixelart'

        if themeHashtags.length is 0
          # We don't have anything but the #pixel_dailies hashtag, so flag the error.
          theme.processingError = @Theme.ProcessingError.NoExtraHashtag

        else
          theme.hashtags = themeHashtags

      else
        # We don't have the #pixel_dailies hashtag, so flag the error.
        theme.processingError = @Theme.ProcessingError.MissingPixelDailiesHashtag

      # Insert the processed theme into the database.
      @Theme.documents.insert theme
      
  @_findThemeForTweet: (tweet) ->
    # Only consider themes in the last 5 days from the tweet.
    tweetTime = new Date tweet.created_at

    dayMilliseconds = 1000 * 60 * 60 * 24
    oneWeekEarlier = new Date tweetTime.getTime() - 5 * dayMilliseconds

    themes = @Theme.documents.find(
      hashtags:
        $exists: true
      time:
        # Before the tweet.
        $lt: tweetTime

        # After one week earlier than the tweet.
        $gt: oneWeekEarlier
    ,
      fields:
        time: 1
        hashtags: 1
    ).fetch()

    unless themes.length
      console.warn "No themes found in the last 5 days. That's weird.", tweetTime
      return

    tweetText = (tweet.full_text or tweet.text).toLowerCase()

    # Remove urls.
    urlRegex = /(https?):\/\/([\w_-]+(?:(?:\.[\w_-]+)+))([\w.,@?^=%&:\/~+#-]*[\w@?^=%&\/~+#-])?/g
    tweetText = tweetText.replace urlRegex, ''

    # Remove special characters.
    tweetText = tweetText.replace /\W+/g, ' '
    tweetPhrases = AB.Helpers.generatePhrases text: tweetText

    # Add parameters by which we'll sort how good a match the theme is.
    for theme in themes
      theme.exactMatchCount = 0
      theme.fuzzyMatchCount = 0

      # Try to see if a theme hashtag is in the text.
      for themeHashtag in theme.hashtags
        match = AB.Helpers.phraseLikelihoodInText phrase: themeHashtag, textPhrases: tweetPhrases
        theme.exactMatchCount++ if match is 1
        theme.fuzzyMatchCount = Math.max match, theme.fuzzyMatchCount

    # Sort to find the best theme.
    themes.sort (a, b) ->
      # Sort descending by exact match count.
      return b.exactMatchCount - a.exactMatchCount unless a.exactMatchCount is b.exactMatchCount

      # Sort descending by fuzzy match count.
      b.fuzzyMatchCount - a.fuzzyMatchCount

    #if not themes[0].exactMatchCount and themes[0].fuzzyMatchCount > 0.5
      #console.log "Fuzzy match made on", tweetText, themes

    # Don't do a match with a theme that didn't get an exact match and fuzzy match is below 50%.
    unless themes[0].exactMatchCount or themes[0].fuzzyMatchCount > 0.5
      #console.log "Couldn't find a good match for tweet:", tweetText, themes
      return

    themes[0]
