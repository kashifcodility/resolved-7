document.addEventListener("DOMContentLoaded", function(event) {

    // ORDER SUMMARY > Show All Items / Hide All Items
    $( "#show_all_items_btn" ).on( "click", function() {
        $( "#summary_items_container" ).hide();
        $( "#summary_all_items_container" ).show();
    });
    $( "#hide_all_items_btn" ).on( "click", function() {
        $( "#summary_items_container" ).show();
        $( "#summary_all_items_container" ).hide();
        window.scrollTo({ top: 0, behavior: 'smooth' });
    });

})