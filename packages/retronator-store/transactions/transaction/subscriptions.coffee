RA = Retronator.Accounts
RS = Retronator.Store

Meteor.publish RS.Transactions.Transaction.forCurrentUser, ->
  # We are doing this inside an autorun in case the user document gets updated and new transactions would get matched.
  @autorun =>
    return unless @userId

    # Select the current user, but we care only about their registered emails
    # or twitter handle since that's how transactions are found.
    user = RA.User.documents.findOne @userId,
      registered_emails: 1
      services:
        twitter:
          screenname: 1

    transactions = RS.Transactions.Transaction.findTransactionsForUser user
    
    # We also need to have user's login services and registered emails so we can match transactions on the client.
    users = RA.User.documents.find
      _id: @userId
    ,
      fields:
        loginServices: true
        registered_emails: true

    # Return both cursors.
    [transactions, users]

Meteor.publish RS.Transactions.Transaction.forGivenGiftKeyCode, (keyCode) ->
  check keyCode, Match.DocumentId

  # This returns the transaction where the key code was gifted. We just need to be able to
  # find it (include keyCode), know what item it is, and get the owner's name.
  RS.Transactions.Transaction.documents.find
    'items.givenGift.keyCode': keyCode
  ,
    fields:
      ownerDisplayName: 1
      items: 1

Meteor.publish RS.Transactions.Transaction.forReceivedGiftKeyCode, (keyCode) ->
  check keyCode, Match.DocumentId

  # This returns the transaction where the key code was received (claimed). We only
  # need to know of its existence, so we know if the key code has been claimed.
  RS.Transactions.Transaction.documents.find
    'items.receivedGift.keyCode': keyCode
  ,
    fields:
      "items.receivedGift.keyCode": 1
