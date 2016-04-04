var amount = 15;
var percent = 10;

$(function() {
    
    $( ".slider-container-1" ).slider({
      value:15,
      min: 0,
      max: 50,
      step: 0.5,
      slide: function( event, ui ) {

        amount = ui.value;
        amount = amount.toFixed(2);

        $( ".amount" ).html( '$' + amount );
        $('#amount-field').val( amount );
        calculatePercentage();
      }
    });

    $( ".slider-container-2" ).slider({
      value:10,
      min: 0,
      max: 100,
      step: 1,
      slide: function( event, ui ) {

      	percent = ui.value;
        $(".p-percent").html( ui.value + "%" );
        $('#processing-percent').val(ui.value);
        
        calculatePercentage();
      }
    });

    $('#pay-btn').click(function(){
		
		$('#buy-book').submit();

	});
});

function calculatePercentage() {

	var percentToProcessing = (parseFloat(amount) * parseFloat(percent)) / 100;
	var percentToAuthor 	= amount - percentToProcessing;
    $('.amount-author').html('$'+percentToAuthor.toFixed(2));
    $('.amount-processing').html('$'+percentToProcessing.toFixed(2));

    $('#pay-btn').html('GET IT FOR $'+amount);

}
