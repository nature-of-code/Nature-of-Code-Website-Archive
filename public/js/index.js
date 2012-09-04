(function() {
  var cleanDollarInput, defaultPrice, dollarToSliderPos, sliderPosToDollar, updateAmountFromSlider, updatePercentFromInput, updatePercentFromSlider;

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
    var sliderAmount;
    sliderAmount = sliderPosToDollar(sliderPos).toFixed(2);
    $('#display-amount').val("$" + sliderAmount);
    $('#amount').val(sliderAmount);
    return this;
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
    $('#percent').val(sliderPos);
    $('#display-percent').val(sliderPos + '%');
    return this;
  };

  jQuery(function() {
    $('#display-percent').blur(function() {
      var raw;
      raw = $(this).val() || 5;
      updatePercentFromInput(raw);
      return false;
    });
    $('#display-percent').change(function() {
      var raw;
      raw = $(this).val() || 5;
      updatePercentFromInput(raw);
      return false;
    });
    $('#display-amount').blur(function() {
      var newAmount, raw;
      raw = $(this).val() || defaultPrice;
      newAmount = cleanDollarInput(raw);
      $('#amount').val(newAmount);
      $('#slider').slider('value', dollarToSliderPos(newAmount));
      $(this).val('$' + newAmount);
      return false;
    });
    $('#display-amount').change(function(event) {
      var newAmount, raw;
      raw = $(this).val() || defaultPrice + '';
      newAmount = cleanDollarInput(raw);
      $('#amount').val(newAmount);
      $('#slider').slider('value', dollarToSliderPos(newAmount));
      $(this).val('$' + newAmount);
      return false;
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
