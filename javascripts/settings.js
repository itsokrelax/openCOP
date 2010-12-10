$(document).ready(function(){
	$('#cancel').bind('click',function(){
		$('#confirm_dialog').fadeOut();
		$('#behind_popup').fadeOut('slow');
	});

//	$('.tooltip').css('color','white'); //this is to counter act the class color that is being inherited from the jquery tabs
	$('#delete_site_level_submit_button').bind('click',function(){
		var site = $('#delete_site_level_name').val();
		var url = 'check_site_level.pl';
		$.ajax({
			type: 'POST',
			url: url,
			data: {site: site},
			success: function(data){
				var error = data.substr(0,1);
				if(error == "0"){
					var str = data.replace(/^[\d\s]/,'');
					delete_site_level();
				} else {
					var str = data.replace(/^[\d\s]/,'');
					$('#confirm_middle').text('');
					$('#confirm_middle').append(str);
					$('#behind_popup').css({'opacity':'0.7'}).fadeIn('slow');
					$('#confirm_dialog').fadeIn('slow');
					var windowWidth = document.documentElement.clientWidth;
					var windowHeight = document.documentElement.clientHeight;
					var popupHeight = $('#confirm_dialog').height();
					var popupWidth = $('#confirm_dialog').width();
					$('#confirm_dialog').css({
						'position': 'absolute',
						'top': windowHeight/2-popupHeight/2,
						'left': windowWidth/2-popupWidth/2
					});
					$('#behind_popup').css({
						'height': windowHeight
					});
				}
			},
			error: function(data){
				alert(data);
			}
		});
	});
	
	$('textarea').each(function(){
		if($(this).attr('textLength') >= 32){
			$(this).attr('rows','8').attr('cols','80');
		}
	});
	
	$('#notify_form').validate({
		rules: {
			email_password: "required",
			email_password2: {
				required: true,
				equalTo: "#email_password"
			}
		}
	});
	
	$('#update').bind('click',function(){
		if($('#notify_form').valid()){
			var o = $.toJSON($('#notify_form').serializeArray());
			$.ajax({
				type: 'POST',
				url: 'update_notification_config.pl',
				data: {object: o},
				success: function(){
					alert("Success");
				},
				error: function(data){
					alert("Error: " + data);
				}
			});
		}
	});
	

});

function delete_site_level(){
	var site = $('#delete_site_level_name').val();
	var url = 'delete_site_level.pl';
		$.ajax({
			type: 'POST',
			url: url,
			data: {site: site},
			success: function(data){
				location.href="settings.pl?delete_site_level_success=1";
			},
			error: function(data){
				alert("Emergency, emergency. There's an emergency going on here.");
			}
		});
}
