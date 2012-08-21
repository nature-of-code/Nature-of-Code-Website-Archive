jQuery ->
  # Get the stripe-key w/o jQuery
  stripeKey = document.querySelector('meta[name="stripe-key"]')['content']
  Stripe.setPublishableKey(stripeKey)
  order.setupForm()

order =
  setupForm: ->
    $('#new-order').submit ->
      $('input[type=submit]').attr('disabled', true)
      if $('#card-number').length
        subscription.processCard()
        false
      else
        true

  processCard: ->
    card =
      number: $('#card-number').val()
      cvc: $('#card-code').val()
      expMonth: $('#card-month').val()
      expYear: $('#card-year').val()
    Stripe.createToken(card, order.handleStripeResponse)

  handleStripeResponse: (status, response) ->
    if status == 200
      $('#order-stripe-card-token').val(response.id)
      $('#new-subscription')[0].submit()
    else
      $('#stripe-error').text(response.error.message)
      $('input[type=submit]').attr('disabled', false)
