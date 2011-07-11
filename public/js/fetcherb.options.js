var time_option = $('#options #time')

$.getJSON('/options', function(data) {
  $.each(data, function(key, val) {
  	if(key!="verbose") {
	  	$("#options #" + key).val(val)
	}
  });	
  $("#options #verbose").checked = data.verbose
});


time_option.datetimepicker({
	showSecond: true,
	dateFormat: 'yyyy-mm-dd',
	timeFormat: 'hh:mm:ss'
});


