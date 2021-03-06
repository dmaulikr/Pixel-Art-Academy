AB = Artificial.Babel
AE = Artificial.Everywhere
AM = Artificial.Mirage
LOI = LandsOfIllusions
RA = Retronator.Accounts
RS = Retronator.Store
HQ = Retronator.HQ

class Retronator.HQ.Items.Receipt extends HQ.Items.Components.Stripe
  @id: -> 'Retronator.HQ.Items.Receipt'
  @url: -> 'retronator/store/receipt'

  @register @id()
  template: -> @id()

  @version: -> '0.0.1'

  @fullName: -> "store receipt"
  @shortName: -> "receipt"
  @nameAutoCorrectStyle: -> LOI.Avatar.NameAutoCorrectStyle.Name

  @description: ->
    "
      It's the receipt for things you bought in Retronator Store.
    "

  @initialize()

  constructor: (@options) ->
    super

    # Fields that control supporter display for logged out users (guests).
    @guestShowSupporterName = @state.field 'showSupporterName', default: true
    @guestSupporterName = @state.field 'supporterName'

    @tipStateFields =
      amount: @state.field 'tip.amount', default: 0
      message: @state.field 'tip.message'

    @scrolled = new ReactiveField false
    @scrolledToBottom = new ReactiveField false

    @purchaseItems = new ReactiveField []

  onCreated: ->
    super

    @scrolled false
    @scrolledToBottom false

    # Get all store items data.
    @subscribe RS.Transactions.Item.all

    # Get top recent transactions to display the supporters list.
    @subscribe RS.Transactions.Transaction.topRecent

    # Get store balance and credit so we know if credit can be applied (and the user charged less).
    @subscribe RA.User.storeDataForCurrentUser
    
    # Get user's contact email so we can pre-fill it in Stripe Checkout.
    @subscribe RA.User.contactEmailForCurrentUser

    @_userBabelSubscription = AB.subscribeNamespace 'Retronator.Accounts.User'

    @autorun (computation) =>
      contents = HQ.Items.ShoppingCart.state 'contents'

      purchaseItems = for receiptItem in contents
        item = RS.Transactions.Item.documents.findOne catalogKey: receiptItem.item
        continue unless item

        item: item
        isGift: receiptItem.isGift

      @purchaseItems purchaseItems

  onRendered: ->
    super

    $viewportArea = @$('.viewport-area')

    $viewportArea.scroll (event) =>
      @scrolled true

      scrollTop = $viewportArea.scrollTop()
      viewportHeight = $viewportArea.height()

      totalHeight = $viewportArea[0].scrollHeight
      maxScrollTop = totalHeight - viewportHeight

      # We use greater or equal because elastic scrolling can overshoot the max number.
      @scrolledToBottom scrollTop >= maxScrollTop

    @display = LOI.adventure.getCurrentThing HQ.Store.Display

    Meteor.setTimeout =>
      @_scrollToNewSupporter duration: 1000
    ,
      1000

  onDestroyed: ->
    super

  showSupporterName: ->
    user = Retronator.user()

    if user then user.profile?.showSupporterName else @guestShowSupporterName()

  supporterName: ->
    return unless @showSupporterName()

    user = Retronator.user()

    if user then user.profile.name else @guestSupporterName()
    
  anonymousPlaceholder: ->
    AB.translate(@_userBabelSubscription, 'Anonymous').text
    
  anonymousYesAttributes: ->
    checked: true if @showSupporterName()

  anonymousNoAttributes: ->
    checked: true unless @showSupporterName()

  itemsPrice: ->
    # The sum of all items to be purchased.
    _.sum (storeItem.item.price for storeItem in @purchaseItems())

  totalPrice: ->
    # Total is the items price with added tip.
    @itemsPrice() + (@tipStateFields.amount() or 0)

  creditApplied: ->
    storeCredit = Retronator.user()?.store?.credit or 0

    # Credit is applied up to the amount in the shopping cart.
    Math.min storeCredit, @totalPrice()

  paymentAmount: ->
    # See how much the user will need to pay to complete this transaction, after the credit is applied.
    storeCredit = Retronator.user()?.store?.credit or 0

    # Existing store credit decreases the needed amount to pay, but of course not below zero.
    Math.max 0, @totalPrice() - storeCredit

  topRecentTransactions: ->
    # First get the existing top 10.
    recentTransactions = RS.Components.TopSupporters.topRecentTransactions.find({},
      sort: [
        ['amount', 'desc']
        ['time', 'desc']
      ]
    ).fetch()

    # Mark as existing transactions.
    transaction.existing = true for transaction in recentTransactions

    # Create new transaction.
    newTransaction =
      name: @supporterName()
      amount: @totalPrice()
      new: true

    newTransaction.message = @tipStateFields.message() if @tipStateFields.amount()

    # Find where the new transaction needs to be inserted. We use
    # a negative amount because the list is in descending order.
    insertIndex = _.sortedIndexBy recentTransactions, newTransaction, (transaction) -> -transaction.amount

    # Add the new transaction and return the result.
    recentTransactions.splice insertIndex, 0, newTransaction
    recentTransactions

  # This overrides the tip plain object in Stripe component parent.
  tip: ->
    amount: @tipStateFields.amount()
    message: @tipStateFields.message()

  events: ->
    super.concat
      'change .anonymous-radio': @onChangeAnonymousRadio
      'input .supporter-name': @onInputSupporterName
      'input .tip-amount': @onInputTipAmount
      'input .tip-message': @onInputTipMessage

  onChangeAnonymousRadio: (event) ->
    showSupporterName = parseInt($(event.target).val()) is 1

    if Meteor.userId()
      Meteor.call "Retronator.Accounts.User.setShowSupporterName", showSupporterName

    else
      @guestShowSupporterName showSupporterName

  onInputSupporterName: (event) ->
    name = $(event.target).val()
    @guestSupporterName name

  onInputTipAmount: (event) ->
    enteredString = $(event.target).val()

    # Make sure the entered value is a number.
    try
      enteredValue = parseFloat enteredString

    catch
      enteredValue = 0

    # If negative sign is entered the parsing succeeds with a NaN value.
    enteredValue = 0 if _.isNaN enteredValue

    # Constrain between 0 and 1000 and round to dollar amount.
    value = Math.floor _.clamp enteredValue, 0, 1000

    # Rewrite the value in the input if needed.
    newString = "#{value}"
    $(event.target).val newString unless newString is enteredString

    oldValue = @tipStateFields.amount()
    @tipStateFields.amount value

    @display.smile() if value > oldValue

    @_scrollToNewSupporter()

  _scrollToNewSupporter: (options = {}) ->
    options.duration ?= 200

    Tracker.afterFlush =>
      $newSupporter = $('.retronator-store-components-top-supporters .new.supporter')

      # Scroll to one higher if possible so that the user sees how much they need to go higher.
      $previousSupporter = $newSupporter.prev()
      $scrollTarget = if $previousSupporter.length then $previousSupporter else $newSupporter
      $scrollContainer = $('.retronator-hq-store-display .screen .content-area')
      middleHeight = $scrollContainer.outerHeight() / 2
      targetTop = $scrollTarget.position().top - middleHeight

      $scrollContainer.stop().animate scrollTop: targetTop, options.duration

  onInputTipMessage: (event) ->
    message = $(event.target).val()
    @tipStateFields.message message

  _completePurchase: ->
    super

    @transactionCompleted = true

    @display.smile()

    # Reset the shopping cart state.
    HQ.Items.ShoppingCart.clearItems()

    # Reset the tip
    @tipStateFields.amount 0
    @tipStateFields.message null

    # deactivate receipt after 4 seconds.
    Meteor.setTimeout =>
      @deactivate()
    ,
      4000

  # Components

  class @SupporterName extends AM.DataInputComponent
    @register 'Retronator.HQ.Items.Receipt.SupporterName'

    load: ->
      user = RA.User.documents.findOne Meteor.userId(),
        fields:
          'profile.name': 1

      user?.profile?.name

    save: (value) ->
      Meteor.call "Retronator.Accounts.User.rename", value

    placeholder: ->
      # We display the same placeholder as with the custom input when we're not logged in.
      receipt = @parentComponent()
      AB.translateForComponent(receipt, 'Your name here').text
