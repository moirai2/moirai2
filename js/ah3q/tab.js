$(document).ready(function() {
	let tabs=$(".tab");
	let index=window.sessionStorage.getItem("index")
	if(index==null)index=0;
	$(".tab").removeClass("active").eq(index).addClass("active");
	$(".content").removeClass("show").eq(index).addClass("show");
	$(".tab").on("click", function() {
		$(".active").removeClass("active");
		$(this).addClass("active");
		const index=tabs.index(this);
		$(".content").removeClass("show").eq(index).addClass("show");
		window.sessionStorage.setItem("index",index);
	})
})

function changeTab(string){
	$(".tab").each(function(){
		console.log(this);
	});
}