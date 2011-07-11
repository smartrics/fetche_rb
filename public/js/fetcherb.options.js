var time_option = $('#options #time')

$.getJSON('/options', function(data) {
	$.each(data, function(key, val) {
		if (key != "verbose") {
			$("#options #" + key).val(val)
		}
	});
	if(data.verbose) {
		$("#options #verbose").attr("checked", true);
	} else {
		$("#options #verbose").removeAttr("checked");
	}
});

time_option.datetimepicker({
	showSecond : true,
	dateFormat : 'yy-mm-dd',
	timeFormat : 'hh:mm:ss'
});
