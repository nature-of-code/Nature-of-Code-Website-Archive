defaultPrice = 10.00

dollarToSliderPos = (dollar) -> dollar * 4

sliderPosToDollar = (sliderPos) -> sliderPos * .25

calculateBreakdown = ->
  totalAmount = parseFloat $('#amount').val()
  donationPercent = (parseFloat $('#percent').val()) / 100.0
  donationDollars = totalAmount * donationPercent
  $('#author-dollars').text("$#{(totalAmount - donationDollars).toFixed(2)}")
  $('#donation-dollars').text("$#{donationDollars.toFixed(2)}")

cleanDollarInput = (dollarInput) ->
  noDollar = dollarInput.replace('$','')
  dollarFloat = parseFloat(noDollar).toFixed(2) || defaultPrice
  if(dollarFloat < 0)
    return defaultPrice.toFixed(2)
  else
    return dollarFloat

updateAmountFromSlider = (sliderPos) ->
  sliderAmount = sliderPosToDollar(sliderPos).toFixed(2)
  $('#display-amount').val("$"+sliderAmount)
  $('#amount').val(sliderAmount)
  calculateBreakdown()
  @

updateAmountFromInput = ->
  raw = $('#display-amount').val() || defaultPrice
  newAmount = cleanDollarInput(raw)
  $('#amount').val(newAmount)
  $('#slider').slider('value',dollarToSliderPos(newAmount))
  $(this).val('$'+newAmount)
  calculateBreakdown()
  @

updatePercentFromInput = (percentString) ->
  percent = parseInt(percentString.replace('%','')) || 5
  if(percent < 0)
    percent = 0
  else if (percent > 100)
    percent = 100

  $('#percent-slider').slider('value',percent)
  $('#percent').val(percent)
  $('#display-percent').val(percent+'%')
  calculateBreakdown()
  false

updatePercentFromSlider = (sliderPos) ->
  $('#percent').val(sliderPos)
  $('#display-percent').val(sliderPos + '%')
  calculateBreakdown()
  @

jQuery ->
  # Replace email
  $('.eml').html("<a href='ma"+"il"+"to:dan"+"iel"+"@"+"shiffman.net'>daniel" +
    "@shi" +"ffman"+".net</a>");


  $('#display-percent').blur ->
    raw = $(this).val() || 5
    updatePercentFromInput(raw)
    false

  $('#display-percent').change ->
    raw = $(this).val() || 5
    updatePercentFromInput(raw)
    false

  $('#display-amount').blur ->
    updateAmountFromInput()
    false

  $('#display-amount').change ->
    updateAmountFromInput()
    false

  $('#percent-slider').slider({
    value: 5,
    animate: true,
    slide:  (e,ui) -> updatePercentFromSlider(ui.value),
    stop:   (e,ui) -> updatePercentFromSlider(ui.value)
  })

  $('#slider').slider({
    value: dollarToSliderPos(defaultPrice),
    animate: true,
    create: () -> updateAmountFromSlider(dollarToSliderPos(defaultPrice)),
    slide: (e,ui) -> updateAmountFromSlider(ui.value),
    stop: (e,ui) -> updateAmountFromSlider(ui.value)
  })