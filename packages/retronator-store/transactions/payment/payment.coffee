AM = Artificial.Mummification
RA = Retronator.Accounts
RS = Retronator.Store

class RetronatorStoreTransactionsPayment extends AM.Document
  # type: what kind of payment this was
  # amount: USD value added to the balance with this payment
  #
  # KICKSTARTER PLEDGE
  # backerEmail: Kickstarter user's email who made the pledge
  # project: name of the project the pledge is associated with
  # backerNumber: kickstarter backer number
  # backerId: kickstarter backer UID
  # backerName: kickstarter backer Name
  #
  # STRIPE PAYMENT
  # authorizedOnly: true if the amount was not actually collected and this is just an intended payment
  # stripeCustomerId: customer id returned from stripe API
  #
  # REFERRAL CODE
  # referralCode: the code used for the referral
  # referralUser: the user who referred this customer, the owner of the referral code
  #   _id
  #   displayName
  #
  # STORE CREDIT
  # storeCreditAmount: USD value of store credit used
  @Meta
    name: 'RetronatorStoreTransactionsPayment'
    fields: =>
      referralUser: @ReferenceField RA.User, ['displayName'], false
      
  @forCurrentUser: 'Retronator.Store.Transactions.Payment.forCurrentUser'

  @Types:
    KickstarterPledge: 'KickstarterPledge'
    StripePayment: 'StripePayment'
    ReferralCode: 'ReferralCode'
    StoreCredit: 'StoreCredit'

  @Projects:
    PixelArtAcademy: 'PixelArtAcademy'

RS.Transactions.Payment = RetronatorStoreTransactionsPayment
