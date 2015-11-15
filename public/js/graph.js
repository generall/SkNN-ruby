var explode = function()
{
	$.getJSON("/cluster?vertex=" + window.selected_vertex + "&centroids=" +  $(this).attr("factor"), function(data){
		location.reload();
	})
}