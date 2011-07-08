$.getJSON('/options', function(data) {
  $.each(data, function(key, val) {
  	if(key!="verbose") {
	  	$("#options #" + key).val(val)
	}
  });	
  $("#options #verbose").checked = data.verbose
});