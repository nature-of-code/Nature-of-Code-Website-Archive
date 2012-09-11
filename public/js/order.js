(function() {
  var setupForm, stripeResponseHandler;

  jQuery(function() {
    var stripeKey;
    stripeKey = document.querySelector('meta[name="stripe-key"]')['content'];
    Stripe.setPublishableKey(stripeKey);
    setupForm();

    $('#paypal-toggle').click(function() {
      $('#new-order').unbind();
      $(this).val('true');
    });
  });

  stripeResponseHandler = function(status, response) {
    if (response.error) {
      $('#payment-errors').text(response.error.message);
      return $('.submit-button').removeAttr('disabled');
    } else {
      $('#order-stripe-card-token').val(response['id']);
      return $('#new-order')[0].submit();
    }
  };

  setupForm = function() {
    $('#new-order').submit(function(event) {
      if ($('#order-email').val().match(/\S+?@\S+?\.[a-zA-Z]{2,}$/)) {
        $('.submit-button').attr('disabled', true);
        Stripe.createToken({
          number: $('#card-number').val(),
          cvc: $('#card-code').val(),
          expMonth: $('#card-month').val(),
          expYear: $('#card-year').val(),
          name: "" + ($('#order-first-name').val()) + " " + ($('#order-last-name').val())
        }, stripeResponseHandler);
      } else {
        $('#payment-errors').text("Please enter an email address.");
      }
      return false;
    });
  };

}).call(this);
