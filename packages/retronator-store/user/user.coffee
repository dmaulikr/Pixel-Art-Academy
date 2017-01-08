RA = Retronator.Accounts
RS = Retronator.Store

# Override the user class with extra store functionality.
class RetronatorAccountsUser extends RA.User
  # profile: a custom object, writable by default by the client
  #   supporterName: the name the user wants to publicly display as a supporter
  #   showSupporterName: boolean whether to use the supporter name or not
  # supporterName: auto-generated supporter name
  # supportAmount: generated sum of all payments
  # store:
  #   balance: the sum of all payments minus sum of all purchases
  #   credit: positive part of balance
  # items: generated array of items owned by this user
  #   _id
  #   catalogKey
  @Meta
    name: 'RetronatorAccountsUser'
    replaceParent: true
    collection: Meteor.users
    fields: (fields) =>
      _.extend fields,
        supporterName: @GeneratedField 'self', ['profile'], (user) ->
          supporterName = if user.profile?.showSupporterName then user.profile?.supporterName else null
          [user._id, supporterName]

        items: [@ReferenceField RS.Transactions.Item, ['catalogKey']]

      fields

    triggers: (triggers) =>
      _.extend triggers,
        # Transactions for a user can update when a new registered email is added or a twitter account is linked.
        transactionsUpdated: @Trigger ['registered_emails', 'services.twitter.screenName'], (user, oldUser) ->
          user?.onTransactionsUpdated()

      triggers

  @topSupporters: 'Retronator.Accounts.User.topSupporters'
  @supportAmountForCurrentUser: 'Retronator.Accounts.User.supportAmountForCurrentUser'
  @storeDataForCurrentUser: 'Retronator.Accounts.User.storeDataForCurrentUser'

  authorizedPaymentsAmount: ->
    # Authorized payments amount is the sum of all payments that were only authorized.
    transactions = RS.Transactions.Transaction.findTransactionsForUser(@).fetch()

    authorizedPaymentsAmount = 0

    for transaction in transactions when transaction.payments
      authorizedPaymentsAmount += payment.amount for payment in transaction.payments when payment.authorizedOnly

    authorizedPaymentsAmount

  hasItem: (catalogKey) ->
    return true if _.find @items, (item) ->
      item.catalogKey is catalogKey

    false

  onTransactionsUpdated: ->
    @generateItemsArray()
    @generateSupportAmount()
    @generateStoreData()

  generateItemsArray: ->
    # Start by constructing an array of all item Ids.
    itemIds = []
    transactions = RS.Transactions.Transaction.findTransactionsForUser(@).fetch()

    # Helper function that recursively adds items.
    addItem = (item) =>
      item = RS.Transactions.Item.documents.findOne item._id

      # Add the item to the ids.
      itemIds = _.union itemIds, [item._id]

      if item.items
        # This is a bundle. Add all items of the bundle as well.
        addItem bundleItem for bundleItem in item.items

    # Add the items from each transaction except those given away as gifts.
    for transaction in transactions
      for transactionItem in transaction.items
        addItem transactionItem.item unless transactionItem.givenGift

    # Create an array of item objects.
    items = _.map itemIds, (id) -> {_id: id}

    @constructor.documents.update @_id,
      $set:
        items: items

  generateSupportAmount: ->
    # Support amount is the sum of all payments.
    transactions = RS.Transactions.Transaction.findTransactionsForUser(@).fetch()

    supportAmount = 0

    for transaction in transactions when transaction.payments
      supportAmount += payment.amount for payment in transaction.payments

    @constructor.documents.update @_id,
      $set:
        supportAmount: supportAmount

  generateStoreData: ->
    # Store balance is the sum of all payments minus sum of all purchases.
    transactions = RS.Transactions.Transaction.findTransactionsForUser(@).fetch()

    balance = 0

    for transaction in transactions
      if transaction.payments
        balance += payment.amount for payment in transaction.payments when not payment.authorizedOnly

      balance -= transactionItem.price for transactionItem in transaction.items when transactionItem.price
      balance -= transaction.tip.amount if transaction.tip

    # Credit is any positive balance that the user can spend towards new purchases.
    credit = Math.max 0, balance

    @constructor.documents.update @_id,
      $set:
        store:
          balance: balance
          credit: credit

RA.User = RetronatorAccountsUser