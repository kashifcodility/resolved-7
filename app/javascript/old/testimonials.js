// TESTIMONIALS CAROUSEL
$(document).ready(function(){
    $("#testimonial-slider").owlCarousel({
        items:1,
        itemsDesktop:[1000,1],
        itemsDesktopSmall:[979,1],
        itemsTablet:[768,1],
        pagination: true,
        slideSpeed:1000,
        singleItem:true,
        transitionStyle:"fadeUp",
        autoPlay:true
    });
});

