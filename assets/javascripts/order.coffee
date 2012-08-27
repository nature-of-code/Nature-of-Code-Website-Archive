jQuery ->
  # Get the stripe-key w/o jQuery
  stripeKey = document.querySelector('meta[name="stripe-key"]')['content']
  Stripe.setPublishableKey(stripeKey)
  setupForm()

stripeResponseHandler = (status, response) ->
  if response.error
    $('#payment-errors').text response.error.message
    $('.submit-button').removeAttr('disabled')
  else
    $('#order-stripe-card-token').val response['id']
    $('#new-order')[0].submit()


setupForm = ->
  $('#new-order').submit (event) ->
    $('.submit-button').attr('disabled',true)
    Stripe.createToken {
      number: $('#card-number').val()
      cvc: $('#card-code').val()
      expMonth: $('#card-month').val()
      expYear: $('#card-year').val()}, stripeResponseHandler
    false