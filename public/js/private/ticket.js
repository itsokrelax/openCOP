;(function(){
	$(function(){
		$('.edit.btn').click(function(){
			var $this = $(this);
			$('.static').each(function(index,element){
				$(element).addClass('hidden');
			});
			$('.input').each(function(index,element){
				$(element).removeClass('hidden');
			});
			$this.hide();
			$('.save.btn').removeClass('hidden');
		});
		
		$('.save.btn').click(function(){
			var data = {};
			$('.input .form-control').each(function(index,element){
				data[$(element).attr('id')] = $(element).val();
			});
			$('.input').each(function(index,element){
				data[$(element).attr('id')] = $(element).val();
			});
			data['csrf_token'] = $('#csrf_token').val();
			$.ajax({
				url: '/ticket/update/' + $('#ticket_id').val(),
				method: 'POST',
				data: JSON.stringify(data),
				dataType: 'json'
			}).done(function(data){
				
			});
		});
		
		$('.add.troubleshooting.btn').click(function(){
			var $form = $(this).parent().parent().find('form');
			var data = $form.serialize();
			$.ajax({
				url: $form.attr('action'),
				method: $form.attr('method'),
				data: data
			}).done(function(data){
				alert('troubleshooting added');
			});
		});
	});
})();