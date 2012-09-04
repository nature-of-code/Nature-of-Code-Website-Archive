(function() {
  var cleanDollarInput, defaultPrice, dollarToSliderPos, sliderPosToDollar, updateAmountFromSlider, updatePercentFromInput, updatePercentFromSlider, updateSliderFromAmount;

  defaultPrice = 20.00;

  dollarToSliderPos = function(dollar) {
    return dollar * 2;
  };

  sliderPosToDollar = function(sliderPos) {
    return sliderPos * .5;
  };

  cleanDollarInput = function(dollarInput) {
    var dollarFloat, noDollar;
    noDollar = dollarInput.replace('$', '');
    dollarFloat = parseFloat(noDollar).toFixed(2) || defaultPrice;
    if (dollarFloat < 0) {
      return defaultPrice.toFixed(2);
    } else {
      return dollarFloat;
    }
  };

  updateAmountFromSlider = function(sliderPos) {
    var amount, displayAmount, sliderAmount;
    amount = document.getElementById('amount');
    displayAmount = document.getElementById('display-amount');
    sliderAmount = sliderPosToDollar(sliderPos).toFixed(2);
    displayAmount.setAttribute('value', "$" + sliderAmount);
    return amount.setAttribute('value', sliderAmount);
  };

  updateSliderFromAmount = function(newAmount) {
    $('#amount').val(newAmount);
    $('#slider').slider('value', dollarToSliderPos(newAmount));
    return false;
  };

  updatePercentFromInput = function(percentString) {
    var percent;
    percent = parseInt(percentString.replace('%', '')) || 5;
    if (percent < 0) {
      percent = 0;
    } else if (percent > 100) {
      percent = 100;
    }
    $('#percent-slider').slider('value', percent);
    $('#percent').val(percent);
    $('#display-percent').val(percent + '%');
    return false;
  };

  updatePercentFromSlider = function(sliderPos) {
    var percentDisplay, percentInput;
    percentInput = document.getElementById('percent');
    percentInput.setAttribute('value', sliderPos);
    percentDisplay = document.getElementById('display-percent');
    percentDisplay.setAttribute('value', sliderPos + '%');
    return this;
  };

  jQuery(function() {
    $('#display-percent').blur(function() {
      var raw;
      raw = $(this).val() || 5;
      return updatePercentFromInput(raw);
    });
    $('#display-percent').change(function() {
      var raw;
      raw = $(this).val() || 5;
      return updatePercentFromInput(raw);
    });
    $('#display-amount').blur(function() {
      var newDollar, raw;
      raw = $(this).val() || defaultPrice;
      newDollar = cleanDollarInput(raw);
      updateSliderFromAmount(newDollar);
      return $(this).val('$' + newDollar);
    });
    $('#display-amount').change(function(event) {
      var newDollar, raw;
      raw = $(this).val() || defaultPrice + '';
      newDollar = cleanDollarInput(raw);
      updateSliderFromAmount(newDollar);
      return $(this).val('$' + newDollar);
    });
    $('#percent-slider').slider({
      value: 5,
      animate: true,
      slide: function(e, ui) {
        return updatePercentFromSlider(ui.value);
      },
      stop: function(e, ui) {
        return updatePercentFromSlider(ui.value);
      }
    });
    return $('#slider').slider({
      value: dollarToSliderPos(defaultPrice),
      animate: true,
      create: function() {
        return updateAmountFromSlider(dollarToSliderPos(defaultPrice));
      },
      slide: function(e, ui) {
        return updateAmountFromSlider(ui.value);
      },
      stop: function(e, ui) {
        return updateAmountFromSlider(ui.value);
      }
    });
  });

}).call(this);
