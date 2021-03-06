PAA = PixelArtAcademy
LOI = LandsOfIllusions

class PixelArtAcademyPracticeCheckIn extends Document
  # time: the time when post was published
  # character: character that published the post
  #   _id
  #   name
  #   color
  # post: (optional) the external post with the check-in data
  #   url
  # text: (optional) the text of the post
  # artwork: (optional) the artwork associated with the post
  #   _id
  #   image:
  #     url
  # image: (optional) the image associated with the post
  #   url
  # video: (optional) the video associated with the post
  #   url
  # conversations: list of conversations revolving around this check-in
  #   _id
  @Meta
    name: 'PixelArtAcademyPracticeCheckIn'
    fields: =>
      character: @ReferenceField LOI.Character, ['name', 'color'], true
      conversation: [@ReferenceField LOI.Conversations.Conversation]

PAA.Practice.CheckIn = PixelArtAcademyPracticeCheckIn
