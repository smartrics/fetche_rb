function confirmDialog(confirmCallback) {
	$("#dialog-confirm").dialog({
		resizable: false,
		height:140,
		modal: true,
		buttons: {
			"Yeah! Go ahead.": function() {
				$(this).dialog("close");
				confirmCallback.call();
			},
			"Nope! Let me look again.": function() {
				$(this).dialog("close");
			}
		}
	});
};

function completionDialog() {
	$("#dialog-complete").dialog({
		resizable: false,
		height:140,
		modal: true,
		buttons: {
			"Thanks!": function() {
				$(this).dialog("close");
			}
		}
	});
};

