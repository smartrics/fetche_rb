jQuery("#grid").jqGrid({
   	url:'/deployments',
	datatype: "json",
   	colNames:['Id', 'Name','Host', 'User', 'Dir','File','Loc', 'Env', 'Tags'],
   	colModel:[
   		{name:'id',index:'id', width:10, editable:false, hidden:true},
   		{name:'name',index:'name', width:55, editable:true},
   		{name:'host',index:'host', width:60, editable:true},
   		{name:'username',index:'username', width:40, editable:true},
   		{name:'logs_dir',index:'logs_dir', width:60, editable:true},
   		{name:'file',index:'file', width:100,editable:true},		
   		{name:'locality',index:'locality', width:32, editable:true, edittype:"select",editoptions:{value:"london:london;newyork:newyork;tokyo:tokyo"}},
   		{name:'environment',index:'environment', width:32, editable:true, edittype:"select",editoptions:{value:"dev:dev;demo:demo;uat:uat;prod:prod"}},
   		{name:'tags',index:'tags', sortable:false, editable:true}		
   	],
   	rowNum:50,
	rowTotal: 2000,
   	rowList:[20,30,40],
   	pager: '#pager',
   	height: "auto",
   	sortname: 'name',
    viewrecords: true,
    autowidth: true,
    sortorder: "desc",
    caption:"Deployments",
    editurl: '/deployments',
	grouping:true,
   	groupingView : {
   		groupField : ['environment'],
   		groupColumnShow : [true],
   		groupText : ['<b>{0} - {1} Item(s)</b>'],
   		groupCollapse : false,
		groupOrder: ['asc']   		
   	}
   	});
jQuery("#grid").jqGrid('navGrid','#pager',
	{edit:true,add:true,del:true}, 
	{reloadAfterSubmit:false}, // edit
	{reloadAfterSubmit:false}, // add
	{reloadAfterSubmit:false} // del
	);
jQuery("#grid").jqGrid('filterToolbar',{stringResult: true,searchOnEnter : true});
jQuery("#grid").jqGrid('navButtonAdd','#pager',{
    caption: "Columns",
    title: "Reorder Columns",
    onClickButton : function (){
        jQuery("#grid").jqGrid('columnChooser');
    }
});
function formToJSON( selector )
{
     var form = {};
     $(selector).find(':input[name]:enabled').each( function() {
         var self = $(this);
         var name = self.attr('name');
         var val = self.val();
         if(name=="verbose") {
         	val = self.attr('checked');
         } 

         if (form[name]) {
            form[name] = form[name] + ',' + self.val();
         }
         else {
            form[name] = self.val();
         }
     });

     return form;
}


jQuery("#grid").jqGrid('navButtonAdd','#pager',{
    caption: "Submit",
    title: "Start retrieval",
    buttonicon: "ui-icon-calculator",
    onClickButton : function (){
		confirmDialog(function(){
			var ids = $('#grid').jqGrid('getCol', 'id', false);
			var names = $('#grid').jqGrid('getCol', 'name', false);
			var options = formToJSON("#options")
	    	var jqxhr = $.post("/fetcher", {"ids" : ids, "names" : names, "options" : options})
		    // Set another completion function for the request above
	    	jqxhr.complete(completionDialog);
		});
    }
});


$("#pager_left table.navtable tbody tr").append(
'<td class="ui-pg-button ui-corner-all"><div class="ui-pg-div">' +
  '<span class="ui-icon ui-icon-shuffle"></span>' +
  '<select id="chngroup" class="ui-pg-selbox">' +
    '<option value="host">Host</option>' +
    '<option value="environment" selected="true">Environment</option>' +
    '<option value="locality">Locality</option>' +
  '</select>' + 
'</div></td>'
);

    
jQuery("#chngroup").change(function(){
	var vl = $(this).val();
	if(vl) {
		if(vl == "clear") {
			jQuery("#grid").jqGrid('groupingRemove',true);
		} else {
			jQuery("#grid").jqGrid('groupingGroupBy',vl);
		}
	}
});
    

