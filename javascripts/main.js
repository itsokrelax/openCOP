$(document).ready(function(){
	$("#report_link").mouseover(function(){
		$("#ticket_sub").addClass("hidden_menu");
		$("#inventory_sub").addClass("hidden_menu");
		$("#admin_sub").addClass("hidden_menu");
		$("#report_sub").removeClass("hidden_menu");
	});
	$("#ticket_link").mouseover(function(){
		$("#report_sub").addClass("hidden_menu");
		$("#inventory_sub").addClass("hidden_menu");
		$("#admin_sub").addClass("hidden_menu");
		$("#ticket_sub").removeClass("hidden_menu");
	});
	$("#inventory_link").mouseover(function(){
		$("#ticket_sub").addClass("hidden_menu");
		$("#report_sub").addClass("hidden_menu");
		$("#admin_sub").addClass("hidden_menu");
		$("#inventory_sub").removeClass("hidden_menu");
	});
	$("#admin_link").mouseover(function(){
		$("#ticket_sub").addClass("hidden_menu");
		$("#inventory_sub").addClass("hidden_menu");
		$("#report_sub").addClass("hidden_menu");
		$("#admin_sub").removeClass("hidden_menu");
	});
	
	$(".sub_link").hoverIntent(function(){
		$(this).addClass("highlighted_link");
	},function(){
		$(this).removeClass("highlighted_link");
	});
	
	$(".customer_link").hoverIntent(function(){
		$(this).addClass("highlighted_link");
	},function(){
		$(this).removeClass("highlighted_link");
	});
});