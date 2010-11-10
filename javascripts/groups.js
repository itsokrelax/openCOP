$(document).ready(function(){
	$('.multiselect').livequery(function(){
		$('.multiselect').multiselect();
		$('.ui-multiselect').show();
	});

	$('#select_user_select').livequery(function(){
		$('#select_user_select').change(function(){
			if($('#select_user_select').val()){
				load_associations_ug();
			}
		});
	});

	$('#select_group_select').livequery(function(){
		$('#select_group_select').change(function(){
			if($('#select_group_select').val()){
				load_associations_gu();
			}
		});
	});

	$('#submit_a_ug').bind('click', function(){
		var ug_select_string = "";
		var ug_unselect_string = "";
		var mode = "associate_ug";
		var uid = $('#select_user_select').val();
		$('#a_ug_append_div ul.selected').children().each(function(e){
			if($(this).attr("title") !== ""){
				ug_select_string += $(this).attr("value") + ":";
			}
		});
		$('#a_ug_append_div ul.available').children().each(function(e){
			if($(this).attr("title") !== ""){
				ug_unselect_string += $(this).attr("value") + ":";
			}
		});
		$.blockUI({message: "Submitting"});
		$.ajax({
			type: 'POST',
			url: 'groups_getdata.pl',
			data: {uid: uid, mode: mode, selected: ug_select_string, unselected: ug_unselect_string},
			success: function(data){
				var error = data.substr(0,1);
				if(error == "0"){
					var str = data.replace(/^[\d\s]/,'');
				} else if(error == "1"){
					var str = data.replace(/^[\d\s]/,'');
				}
				if($('#select_group_select').val()){
					load_associations_gu();
				}
				$.unblockUI();
			},
			error: function(){
				alert("Error");
				$.unblockUI();
			}
		});
	});

	$('#submit_a_gu').bind('click', function(){
		var gu_select_string = "";
		var gu_unselect_string = "";
		var mode = "associate_gu";
		var gid = $('#select_group_select').val();
		$('#a_gu_append_div ul.selected').children().each(function(e){
			if($(this).attr("title") !== ""){
				gu_select_string += $(this).attr("value") + ":";
			}
		});
		$('#a_gu_append_div ul.available').children().each(function(e){
			if($(this).attr("title") !== ""){
				gu_unselect_string += $(this).attr("value") + ":";
			}
		});
		$.blockUI({message: "Submitting"});
		$.ajax({
			type: 'POST',
			url: 'groups_getdata.pl',
			data: {gid: gid, mode: mode, selected: gu_select_string, unselected: gu_unselect_string},
			success: function(data){
				var error = data.substr(0,1);
				if(error == "0"){
					var str = data.replace(/^[\d\s]/,'');
				} else if(error == "1"){
					var str = data.replace(/^[\d\s]/,'');
				}
				if($('#select_group_select').val()){
					load_associations_ug();
				}
				$.unblockUI();
			},
			error: function(){
				alert("Error");
				$.unblockUI();
			}
		});
	});
});

function load_associations_ug(){
	var uid = $('#select_user_select').val();
	var mode = "init_ug";
	$.ajax({
		type: 'POST',
		url: 'groups_getdata.pl',
		data: {uid: uid, mode: mode},
		success: function(data){
			$('#a_ug_append_div').text("");
			$('#a_ug_append_div').append(data);
		//	remove_error_label();
		},
		error: function(){
			alert("Error");
		}
	});
}

function load_associations_gu(){
	var gid = $('#select_group_select').val();
	var mode = "init_gu";
	$.ajax({
		type: 'POST',
		url: 'groups_getdata.pl',
		data: {gid: gid, mode: mode},
		success: function(data){
			$('#a_gu_append_div').text("");
			$('#a_gu_append_div').append(data);
		//	remove_error_label();
		},
		error: function(){
			alert("Error");
		}
	});
}
