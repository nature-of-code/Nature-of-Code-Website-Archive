defaultPrice = 20.00

dollarToSliderPos = (dollar) -> dollar * 2

sliderPosToDollar = (sliderPos) -> sliderPos * .5

cleanDollarInput = (dollarInput) ->
  noDollar = dollarInput.replace('$','')
  dollarFloat = parseFloat(noDollar).toFixed(2) || defaultPrice
  if(dollarFloat < 0)
    return defaultPrice.toFixed(2)
  else
    return dollarFloat

updateAmountFromSlider = (sliderPos) ->
  amount = document.getElementById('amount')
  displayAmount = document.getElementById('display-amount')

  sliderAmount = sliderPosToDollar(sliderPos).toFixed(2)

  displayAmount.setAttribute('value',"$"+sliderAmount)
  amount.setAttribute('value',sliderAmount)

updateSliderFromAmount = (newAmount) ->
  $('#amount').val(newAmount)
  $('#slider').slider('value',dollarToSliderPos(newAmount))
  false

updatePercentFromInput = (percentString) ->
  percent = parseInt(percentString.replace('%','')) || 5
  if(percent < 0)
    percent = 0
  else if (percent > 100)
    percent = 100

  $('#percent-slider').slider('value',percent)
  $('#percent').val(percent)
  $('#display-percent').val(percent+'%')
  false

updatePercentFromSlider = (sliderPos) ->
  percentInput = document.getElementById('percent')
  percentInput.setAttribute('value', sliderPos)
  percentDisplay = document.getElementById('display-percent')
  percentDisplay.setAttribute('value', sliderPos + '%')
  @

jQuery ->
  $('#display-percent').blur ->
    raw = $(this).val() || 5
    updatePercentFromInput(raw)

  $('#display-percent').change ->
    raw = $(this).val() || 5
    updatePercentFromInput(raw)

  $('#display-amount').blur ->
    raw = $(this).val() || defaultPrice
    newDollar = cleanDollarInput(raw)
    updateSliderFromAmount(newDollar)
    $(this).val('$'+newDollar)

  $('#display-amount').change (event) ->
    raw = $(this).val() || defaultPrice+''
    newDollar = cleanDollarInput(raw)
    updateSliderFromAmount(newDollar)
    $(this).val('$'+newDollar)

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