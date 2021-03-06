AE = Artificial.Everywhere
AM = Artificial.Mirage
PAA = PixelArtAcademy

Calendar = PAA.PixelBoy.Apps.Calendar

class Calendar.Providers.Practice.CheckInComponent extends AM.Component
  template: ->
    'PixelArtAcademy.PixelBoy.Apps.Calendar.Providers.Practice.CheckInComponent'

  checkIn: ->
    # Fetch full check-in data (we have a bare object with just the id).
    checkIn = @currentData()

    PAA.Practice.CheckIn.documents.findOne checkIn._id

  showEntry: ->
    checkIn = @currentData()

    @showImage() or checkIn.text

  showImage: ->
    checkIn = @currentData()

    checkIn.artwork or checkIn.image or checkIn.post

  textStyle: ->
    checkIn = @currentData()

    color: "##{checkIn.character.colorObject().getHexString()}"

  linkColor: ->
    checkIn = @currentData()

    # Link should be 2 shades lighter than the text.
    checkIn.character.colorObject 2
