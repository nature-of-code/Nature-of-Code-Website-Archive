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
    if $('#order-email').val().match(/\S+?@\S+?\.[a-zA-Z]{2,}$/)
      $('.submit-button').attr('disabled',true)
      Stripe.createToken {
        number: $('#card-number').val()
        cvc: $('#card-code').val()
        expMonth: $('#card-month').val()
        expYear: $('#card-year').val()
        name: "#{$('#order-first-name').val()} #{$('#order-last-name').val()}"
      }, stripeResponseHandler
    else
      $('#payment-errors').text "Please enter an email address."
    false