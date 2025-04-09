//Establishes Root Variable
import { root_path, pdp_path, cart_preview_path, add_to_cart_path, create_favorite_path, remove_favorite_path, update_inventory_status_path } from 'routes';

var root = document.getElementById('home-link').innerHTML;

$(document).ready(function() {

    jQuery('.datepicker-ab').datepicker({
        autoclose: true,
        todayHighlight: true,
        format: 'yyyy-mm-dd',
        startDate: new Date() // This disables previous dates
    });

    $('#sortable-list').sortable({
        handle: '.sort-handle', // Enable sorting only when dragging the handle
        update: function(event, ui) {
          var sortedIDs = $(this).sortable('toArray', { attribute: 'data-id' });
  
          $.ajax({
            url: '/sort_rooms',
            method: 'POST',
            data: {
              order: sortedIDs
            },
            success: function(response) {
              //alert('Room order updated successfully!');
              window.location.reload();
            },
            error: function(xhr) {
              alert('Something went wrong.');
            }
          });
        }
      });


    console.log('load.........')
    $(document).on('click', '#change-quantity-popup', function() {
        console.log('load.........clickkkkkk')
        var itemId = $(this).data('id');
        var action = $(this).data('action');
        var quantity = parseInt($('#item_quantity_popup_' + itemId).text());
        var quantity_max = parseInt($('#popup_' + itemId).text().replace("pieces", "").trim());

        if (action === 'increase' && quantity < quantity_max) {			
            quantity += 1;
            $('#item_quantity_popup_' + itemId).text(quantity);
        } else if (action === 'decrease' && quantity > 1) {  // Ensure quantity doesn't go below 1
            quantity -= 1;
            $('#item_quantity_popup_' + itemId).text(quantity);
        }
    });
});




//Mobile Menu
$(".category-nav-name").click(function(){
  if( $(this).children("#expand_marker").html() == '-'){
     $(this).children("#expand_marker").html('+');
  } else if ( $(this).children("#expand_marker").html('+')){
     $(this).children("#expand_marker").html('-');
  }
  console.log('mobile menu..........');
});

///Account Filter
$(".widget-title").click(function(){
    if($(this).children("#expand_marker").html()=="+") {
       $(this).children("#expand_marker").html('-');
    } else if($(this).children("#expand_marker").html()=="-"){
       $(this).children("#expand_marker").html('+');
    }

});

///Account Filter
$(".main-widget-title").click(function(){
  if( $(this).children(".hide-filters").html() == 'Hide'){
     $(this).children(".hide-filters").html('Show');
  } else if ( $(this).children(".hide-filters").html('Show')){
     $(this).children(".hide-filters").html('Hide');
  }
});


$(document).ready(function(){
  if ($(window).width() < 768) {
    $(".room-option").addClass("collapse");
    }else {
      $(".room-option").removeClass("collapse");
    }
});


// USER PROFILE:
// ACTIVATE TOOLTIP
$(function(){
    $('[data-toggle="popover"]').popover()
});
// CLOSE TOOLTIP BY CLICKING OUTSIDE
$('body').on('click', function (e) {
    //did not click a popover toggle or popover
    if ($(e.target).data('toggle') !== 'popover'
        && $(e.target).parents('.popover.in').length === 0) { 
        $('[data-toggle="popover"]').popover('hide');
    }
});



// Checkout review
if(document.getElementById("checkout_process")) {
    // Disable process button when clicked
    var submit_order_message = document.getElementById('submit_order_message')
    document.getElementById("checkout_process").onsubmit = function() {
        var submit_btn = this.querySelector("button[type=submit]");
        submit_btn.disabled = true;
        submit_btn.value = "Processing...";
        submit_order_message.style.display = "block";
    };
}

//***LOGIN / SIGN UP SWITCH */
$(document).ready(function(){
	$('ul.switcher li').click(function(){
		var tab_id = $(this).attr('data-tab');

		$('li').removeClass('active');
    $('div.tab-pane').removeClass('active');

		$(this).addClass('active');
		$("#"+tab_id).addClass('active');
	})
})


var btn = $('#scrollup');

$(window).scroll(function() {
  if ($(window).scrollTop() > 300) {
    btn.addClass('show');
  } else {
    btn.removeClass('show');
  }
});

btn.on('click', function(e) {
  e.preventDefault();
  $('html, body').animate({scrollTop:0}, '300');
});

function ShowHideDiv() {
	var chkYes = document.getElementById("search-container");
	var hightlight = document.getElementById("location-select");
	hightlight.style.display = chkYes.checked ? "color" : "blue";
}


///***Search Bar Suggestions  */

$('.search-button').click(function(){
  $('#search-input').focus();
});

function showHideSearch() {
	var searchbar= document.getElementById("search-container");
	if (searchbar.style.display == "block"){
		searchbar.style.display = "none";
	}else{
	    searchbar.style.display = "block";
	}
}



$(document).ready(function(){
	$('#nav-icon-d').click(function(){
		$(this).toggleClass('open');
	});
});



/** Disabled until results are de-duplicated/redesigned
    srchInput.addEventListener("keyup", function(e) {
      $(document).ready(function()  {
        srchSugg.innerHTML ="";
        clearTimeout(timeout);
        timeout = setTimeout(function () {
          var url = root+ "products/search_suggest/?q=" +srchInput.value;
          $.getJSON(url, function(data) {
            for (var item in data) {
              srchSugg.style.display = "block";
              var search_product = (data[item].name);
              srchSugg.innerHTML += '<a href="' + root + 'products/'+(data[item].id)+'">'+search_product+'</a></br>';
            } 
            if (srchInput.value == "" || JSON.stringify(url.data)=='[]'){
              srchSugg.innerHTML ="";
              srchSugg.style.display = "none";
            }
          });
        }, 200);
        return false;
      });
    });
**/

/**
 * Toggles form field visibility/requirement
 *
 * NOTE: Inputs are cleared on change.
 * TODO: If we reuse this, consolidate the input types and generate the selector automatically.
 * 
 * wrapper_query_select = query selector for wrapping div of input element(s)
 * is_active = boolean
 * exclude_required = array of input names to exclude
 * clear_values = boolean of whether to clear values on change (excludes radio/checkboxes)
 *
 * Example that makes all cc_field divs visible and their child input/selects required:
 * toggle_inputs('.cc_field', true)
 */
function toggle_inputs(wrapper_query_selector, is_active, exclude_required, clear_values) {
    var exclude_required = Array.isArray(exclude_required) ? exclude_required : Array(exclude_required);
    clear_values = clear_values === false ? false : true;

    var wrapper_else = document.querySelectorAll(wrapper_query_selector);
    var input_else = document.querySelectorAll(wrapper_query_selector + ' input, ' + wrapper_query_selector + ' select');
    for (var i=0; i<wrapper_else.length; i++) {
        wrapper_else[i].style.display = is_active ? 'block' : 'none';
    }
    for (var i=0; i<input_else.length; i++) {
        if (exclude_required.length < 1 || exclude_required.includes(input_else[i].name) == false) {
            input_else[i].required = is_active;
        }

        if (clear_values && ['radio', 'checkbox'].includes(input_else[i].type) == false) {
            input_else[i].value = '';
        }
    }
}


// LOADER
$(document).ready(function(){
    $(".billing_info_form").on("submit", function(){
        $(".loader").fadeIn();
    });

    $("#address").on("submit", function(){
        $(".loader").fadeIn();
    });

    $("#checkout_process").on("submit", function(){
        $(".loader").fadeIn();
    });

    $("#profile_photo_upload").on("submit", function(){
        $(".loader").fadeIn();
    });

    $(".profile_edit_contact_billing").on("submit", function(){
        $(".loader").fadeIn();
    });

    $("#request_destage_form").on("submit", function(){
        $(".loader").fadeIn();
    });
});


//  toggling of dwelling type other
function change_delivery_dwelling_type(ele, clear_values) {
    clear_values = clear_values === false ? false : true;
    switch(ele.value) {
        case 'other':
            toggle_inputs('.delivery_dwelling_other', true, [], clear_values);
            break;
        default:
            toggle_inputs('.delivery_dwelling_other', false, [], clear_values);
    }
}

///Filter orders by type
    $(document).ready(function(){
     // $(".void").hide();
   //   $(".complete").hide();
    });

$(function () {
  $("#renting").click(function () {
      if ($(this).is(":checked")) {
          $(".renting").show();
      } else {
          $(".renting").hide();
      }
  });
});

$(function () {
  $("#open").click(function () {
      if ($(this).is(":checked")) {
          $(".open").show();
      } else {
          $(".open").hide();
      }
  });
});

$(function () {
  $("#complete").click(function () {
      if ($(this).is(":checked")) {
          $(".complete").show();
      } else {
          $(".complete").hide();
      }
  });
});

$(function () {
  $("#void").click(function () {
      if ($(this).is(":checked")) {
          $(".void").show();
      } else {
          $(".void").hide();
      }
  });
});

/// Filter orders by date

function sortTable(n) {
  var table, rows, switching, i, x, y, shouldSwitch, dir, switchcount = 0;
  table = document.getElementById("orders-table");
  switching = true;
  dir = "asc";
  while (switching) {
    switching = false;
    rows = table.rows;
    for (i = 1; i < (rows.length - 1); i++) {
      shouldSwitch = false;
      x = rows[i].getElementsByTagName("TD")[n];
      y = rows[i + 1].getElementsByTagName("TD")[n];
      if (dir == "asc") {
        if (x.innerHTML.toLowerCase() > y.innerHTML.toLowerCase()) {
          shouldSwitch = true;
          break;
        }
      } else if (dir == "desc") {
        if (x.innerHTML.toLowerCase() < y.innerHTML.toLowerCase()) {
          shouldSwitch = true;
          break;
        }
      }
    }
    if (shouldSwitch) {
      rows[i].parentNode.insertBefore(rows[i + 1], rows[i]);
      switching = true;
      switchcount ++;
    } else {
      if (switchcount == 0 && dir == "asc") {
        dir = "desc";
        switching = true;
      }
    }
  }
}

// Product item favorites logic
var favorite_btns = document.getElementsByClassName('favorite_btn');

function bind_favorites() {
    if(favorite_btns.length) {
        $('body').on('click', '.favorite_btn', function(e){
            e.preventDefault();
            var action = this.getAttribute('data-action');
            var btn = this;
            var spinner = document.createElement('div');
            spinner.classList.add('spinner-border');
            spinner.classList.add('spinner-border-sm');
            spinner.setAttribute('role', 'status');
            $.ajax({
                url: action == 'favorite' ? create_favorite_path() : remove_favorite_path(),
                type: action == 'favorite' ? 'POST' : 'DELETE',
                data: { product_id: btn.dataset.pid },
                beforeSend: function(){
                    btn.style.display = 'none';
                    btn.insertAdjacentElement('beforebegin', spinner);
                },
                complete: function() {
                    btn.parentNode.removeChild(spinner);
                    btn.style.display = null;
                },
                success: function(result) {
                    btn_icon = btn.getElementsByTagName('i')[0];
                    if(action == 'favorite') {
                        btn.dataset.action = 'unfavorite';
                        btn_icon.setAttribute('aria-label', 'unfavorite');
                        btn_icon.classList.replace('far', 'fas');
                    } else {
                        btn.dataset.action = 'favorite';
                        btn_icon.setAttribute('aria-label', 'favorite');
                        btn_icon.classList.replace('fas', 'far');
                    }
                }
            });
        })
    }
}

bind_favorites()

// Product quickview
function bind_quickviews() {    
    var qv_btns = document.getElementsByClassName('qv_btn');
    var roomIdElement = document.getElementById('room_id');
                            
    if(qv_btns.length) {
        Array.from(qv_btns).forEach(function(btn) {
            btn.addEventListener('click', function(e) {
                e.preventDefault();
                document.getElementById('qv_body').innerHTML = "";
                
                var spinner = document.createElement('div');
                spinner.classList.add('spinner-border', 'spinner-border-lg');

                var alert = document.createElement('div');
                alert.classList.add('alert', 'alert-danger');
                alert.innerText = 'Error loading product quickview.';

                $.ajax({
                    url: pdp_path(btn.dataset.pid),
                    type: 'GET',
                    beforeSend: function(){
                        var body = document.getElementById('qv_body');
                        body.classList.add('text-center');
                        body.appendChild(spinner);

                       
                        
                       $('#quickview').modal('show');
                    },
                    complete: function() {
                        document.getElementById('qv_body').classList.remove('text-center');
                        
                        spinner.remove();
                    },		     
                    success: function(result) {
                        var qv_modal = $('#quickview');
                        var title = document.getElementById('qv_title');
                        var body = document.getElementById('qv_body');
                        
                        body.removeChild(spinner);

                        if(result.html) {
                            body.innerHTML = result.html;
                            var maxRating = 3; 
                            var starsInner = document.getElementById('fto');
                            var percentage = (parseFloat(btn.dataset.rating) / maxRating) * 100; 
                            if (starsInner) {
                                starsInner.style.width = percentage + '%'; 
                            } 
                            qv_modal.trigger('quickviewLoaded');
                            
                        } else {
                            body.appendChild(alert);
                        }
                    },
                    error: function() {
                        body.appendChild(alert);
                    }
                });
            });
        });
    }
}
$(function() { bind_quickviews(); });

// Adds an item to the cart
function add_to_cart(remaining_quantity, product_id, intent, room , resolve, reject) {
    console.log(room,'room...........');
    // var itemId = $(this).data('id');
        // var action = $(this).data('action');
        var cart_items = parseInt($('#qty_of_items').text());
        var quantity = parseInt($('#item_quantity_popup_' + product_id).text());
    if (room === "0"){
        room_org = document.getElementById('room_id');
        if (room_org){
            room_id =  document.getElementById('room_id').value; 
        }
        else{
            room_id = '0';
        }
    }
    else{
        room_id = room;
    }
    return new Promise(function(resolve, reject) {
	$.ajax({
	    url: Routes.add_to_cart_path(),
	    type: 'POST',
	    data: { remaining_quantity: remaining_quantity, intent: intent, product_id: product_id, room_id: room_id, quantity: quantity },
	    success: function(response) {
        if (response.message !== "Item quantity not available."){
           $('#qty_of_items').text(cart_items + quantity);
        }        
		resolve(response);
	    },
	    error: function(reject) {
		reject(response);
	    }
	})
    })
}



// Adds an item to an order
function add_to_order(order_id, product_id, intent, resolve, reject) {
    return new Promise(function(resolve, reject) {
	$.ajax({
	    url: Routes.add_to_order_path(),
	    type: 'POST',
	    data: { order_id: order_id, product_id: product_id },
	    success: function(response) {
		resolve(response);
	    },
	    error: function(reject) {
		reject(response);
	    }
	})
    })
}

// Removes an item from the PLP
function remove_item_from_listing(product_id) {
    document.getElementById('p_' + product_id).remove();
}


// Refreshes the cart preview dropdown in the header navigation
function refresh_cart_preview() {
    var cart_preview = document.getElementById('cart_preview')
    if(cart_preview) {
	$.ajax({
	    url: Routes.cart_preview_path(),
	    type: 'GET',
	    beforeSend: function(){},
	    complete: function(){},
	    success: function(result) {
            cart_preview.innerHTML = result.html
            document.querySelector('#qty_of_items').textContent = result.qty;
            est_delivery();
	    }
	});
    }

}


///Upsell Cart
function est_delivery(){
    var upsell_el = document.getElementById("est-upsell");
    var cart_sub_el = document.getElementById("cart-subtotal");
    var est_delivery_el = document.getElementById("est-delivery");
    var est_destage_el = document.getElementById("est-destage");
    var cart_total_el =  document.getElementById("cart-total");

    var est_total_val = 0;
    var est_delivery_val = 0;
    var cart_sub_val = +cart_sub_el.textContent;

    var upsell_val = "Your order qualifies for free shipping!"

    if (cart_sub_val<200 || cart_sub_val == false){
        est_delivery_val = 100;
        upsell_val="";
    } else if  (cart_sub_val>200 ){
        est_delivery_val = 100;
        upsell_val = "";
    } 
    upsell_el.innerHTML = upsell_val;
    est_delivery_el.innerHTML = est_delivery_val.toFixed(2);
    est_destage_el.innerHTML = est_delivery_val.toFixed(2);
    est_total_val = est_delivery_val*2 + cart_sub_val;
    cart_total_el.textContent = est_total_val.toFixed(2);
}


if(document.getElementById("cart-subtotal")){
    est_delivery()
}


// Quickview add to cart buttons
$(function(){
    qv_modal = $('#quickview');
    if (qv_modal) {
        qv_modal.on('quickviewLoaded', function (qv_e) {

            // Bind slide show events for this quickview
            show_item_image(this);

            var atc_btns = document.querySelectorAll('#quickview .add_to_cart_btn');

            Array.from(atc_btns).forEach(function(atc_btn) {
                atc_btn.addEventListener('click', function(e) {
                    e.preventDefault();

                    var cta_container = document.querySelector('#quickview #product_ctas');
                    var spinner = document.createElement('div');
                    spinner.classList.add('spinner-border', 'spinner-border-lg');
                    // cta_container.innerHTML = '';
                    cta_container.appendChild(spinner);
                    add_to_cart(atc_btn.dataset.quantity, atc_btn.dataset.pid, atc_btn.dataset.intent, atc_btn.dataset.room)
                        .then(function(response) {
                            // cta_container.innerHTML = '';
                            var notice = document.createElement('div');
                            notice.classList.add('alert');
                            notice.innerText = response.message;

                            if(response.success) {
                                refresh_cart_preview();
                               // remove_item_from_listing(atc_btn.dataset.pid);
                                notice.classList.add('alert-success');
                            } else {
                                notice.classList.add('alert-danger');
                            }

                            cta_container.removeChild(spinner);
                            cta_container.appendChild(notice);			     
                        })
                })
            });

            var ato_frm = document.querySelector('#quickview form#add_to_order');
            if(ato_frm) {
                var ato_selector = ato_frm.elements['order_id'];
                var ato_submit = ato_frm.elements['commit'];

                // Disable submit unless non-empty value
                ato_selector.addEventListener('change', function(e) {
                    ato_submit.disabled = (ato_selector.value == '');
                });

                ato_frm.addEventListener('submit', function(e) {		
                    e.preventDefault();

                    var order_id = ato_frm.elements['order_id'].value
                    var product_id =  ato_frm.elements['product_id'].value
                    var cta_container = document.querySelector('#quickview #product_ctas');
                    var ato_container = document.querySelector('#quickview #ato_container');
                    var ato_confirm = document.querySelector('#quickview #ato_confirm');
                    var ato_confirm_yes = document.querySelector('#quickview #ato_confirm_yes');
                    var ato_confirm_no = document.querySelector('#quickview #ato_confirm_no');

                    ato_frm.classList.add('d-none');
                    ato_confirm.classList.remove('d-none');

                    // Confirmation cancel
                    ato_confirm_no.addEventListener('click', function(e) {
                        ato_confirm.classList.add('d-none');
                        ato_frm.classList.remove('d-none');
                        ato_submit.disabled = false;
                    });

                    ato_confirm_yes.addEventListener('click', function(e) {
                        var spinner = document.createElement('div');
                        spinner.classList.add('spinner-border', 'spinner-border-lg');
                        //cta_container.innerHTML = '';
                        cta_container.appendChild(spinner);

                        add_to_order(order_id, product_id, 'rent')
                            .then(function(response) {
                                var notice = document.createElement('div');
                                notice.classList.add('alert');
                                notice.innerText = response.message;

                                if(response.success) {
                                    remove_item_from_listing(product_id);
                                    notice.classList.add('alert-success');
                                } else {
                                    notice.classList.add('alert-danger');
                                }

                                cta_container.removeChild(spinner);
                                cta_container.appendChild(notice);			
                            })
                    });		
                })
            }
        })
    }     
});

// PLP add to cart/order buttons
// TODO: DRY with quickview logic
$(function(){
if (document.getElementById('pdp')) {
    var atc_btns = document.querySelectorAll('#pdp .add_to_cart_btn');
    Array.from(atc_btns).forEach(function(atc_btn) {
        atc_btn.addEventListener('click', function(e) {
            e.preventDefault();

            var cta_container = document.querySelector('#pdp #product_ctas');
            var spinner = document.createElement('div');
            spinner.classList.add('spinner-border', 'spinner-border-lg');
            //cta_container.innerHTML = '';
            cta_container.appendChild(spinner);
            
            add_to_cart(atc_btn.dataset.quantity, atc_btn.dataset.pid, atc_btn.dataset.intent, atc_btn.dataset.room)
                .then(function(response) {
                    var notice = document.createElement('div');
                    notice.classList.add('alert');
                    notice.innerText = response.message;

                    if(response.success) {
                        refresh_cart_preview();
                        notice.classList.add('alert-success');
                    } else {
                        notice.classList.add('alert-danger');
                    }

                    cta_container.removeChild(spinner);
                    cta_container.appendChild(notice);			     
                })
        })
    })

    var ato_frm = document.querySelector('#pdp form#add_to_order');
    if(ato_frm) {
        var ato_selector = ato_frm.elements['order_id'];
        var ato_submit = ato_frm.elements['commit'];

        // Disable submit unless non-empty value
        ato_selector.addEventListener('change', function(e) {
            ato_submit.disabled = (ato_selector.value == '');
        });

        ato_frm.addEventListener('submit', function(e) {		
            e.preventDefault();

            var order_id = ato_frm.elements['order_id'].value
            var product_id =  ato_frm.elements['product_id'].value
            var cta_container = document.querySelector('#pdp #product_ctas');
            var ato_container = document.querySelector('#pdp #ato_container');
            var ato_confirm = document.querySelector('#pdp #ato_confirm');
            var ato_confirm_yes = document.querySelector('#pdp #ato_confirm_yes');
            var ato_confirm_no = document.querySelector('#pdp #ato_confirm_no');

            ato_frm.classList.add('d-none');
            ato_confirm.classList.remove('d-none');

            // Confirmation cancel
            ato_confirm_no.addEventListener('click', function(e) {
                ato_confirm.classList.add('d-none');
                ato_frm.classList.remove('d-none');
                ato_submit.disabled = false;
            });

            ato_confirm_yes.addEventListener('click', function(e) {
                var spinner = document.createElement('div');
                spinner.classList.add('spinner-border', 'spinner-border-lg');
                //cta_container.innerHTML = '';
                cta_container.appendChild(spinner);

                add_to_order(order_id, product_id, 'rent')
                    .then(function(response) {
                        var notice = document.createElement('div');
                        notice.classList.add('alert');
                        notice.innerText = response.message;

                        if(response.success) {
                            notice.classList.add('alert-success');
                        } else {
                            notice.classList.add('alert-danger');
                        }

                        cta_container.removeChild(spinner);
                        cta_container.appendChild(notice);			
                    })
            });		
        })
    }
}
});



///Contact


if (document.getElementById("Saturday")){
  var day =  {weekday: 'long'};
var weekday =  new Date().toLocaleDateString('en-us', day);
  document.getElementById(weekday).classList.add("current-day"); 
}
    
/// Search orders TODO:Resolve so it only searches on filters

$(document).ready(function(){
  if(document.getElementById("users_orders")){
  var searchlist= document.getElementById("users_orders").style.display;
  if (searchlist!= "none"){
  $("#users_orders").on("keyup", function() {
    var value = $(this).val().toLowerCase();
    $("#users_orders tr").filter(function() {
      $(this).toggle($(this).text().toLowerCase().indexOf(value) > -1)
    });
  });
}
}
}); 


    $(document).ready(function(){
      $("#owned_products").on("keyup", function() {
        var value = $(this).val().toLowerCase();
        $("#owned_products li").filter(function() {
          $(this).toggle($(this).text().toLowerCase().indexOf(value) > -1)
        });
      });
    });

    $(document).ready(function(){
      $("#owned_filter").on("change", function() {
        var value = $(this).val().toLowerCase();
        $("#owned_products li").filter(function() {
          $(this).toggle($(this).text().toLowerCase().indexOf(value) > -1)
        });
      });
    });


//Product Image Options 
function show_item_image( div_parent ){
    var bigimage = $("#imagechange", div_parent)
    $('.thumbnails a', div_parent).each(function(e) {
        $(this).on('click', function(e) {
            imgsrc = $(this).find('.img-src').attr('src');
            bigimage.attr("src", imgsrc).fadeIn(1000);
        });  
    });
}

if(document.getElementsByClassName('.product-detail-page')) {
    show_item_image($('.product-detail-page'));
}



// Accounting page - rental income
if (document.getElementById('year')) {

    var year_selector = $('#year');
    var month_selector = $('input[name=month]');

    function month_name(num) {
        var names = [ "January", "February", "March", "April", "May", "June",
                       "July", "August", "September", "October", "November", "December" ];
        return names[parseInt(num) - 1];
    }

    function update_refresh_href(year, month) {
        var el = $('#date_submit');
        el.attr('href', Routes.account_accounting_income_path() + '?year=' + year + '&month=' + month);
    }
    
    function set_year(year) {
        $(year_selector).text(year);
        update_refresh_href(year, get_month());
    }

    function get_year() {
        return parseInt($(year_selector).text());
    }
    
    function set_month(month) {
        $(month_selector).each(function(e) {
            var mid = $(this).attr('id');
            var label = $('label[for=' + mid + ']');
            if(mid == month) {
                $(this).prop('checked', true);
                label.css('color', 'var(--brand)');
                update_refresh_href(get_year(), month);
            } else {
                label.css('color', '#606060');
            }
        });
    }

    function get_month() {
        var m = null;
        $(month_selector).each(function(e) {
            var mel = $(this);
            if(mel.is(':checked')) {
                m = parseInt(mel.attr('id'));
            }
        });
        return m;
    }

    function set_monthly_total(year, month, total) {
        var label_el = $('#month-income');
        var total_el = $('#sum_month');
        label_el.text(month_name(month) + ', ' + year);
        total_el.text(total);
    }

    function set_yearly_total(year, total) {
        var label_el = $('#year-income');
        var total_el = $('#sum_year');
        label_el.text(year);
        total_el.text(total);
    }

    var summary_data = {};
    function fetch_summary_data(year, month, callback) {
        var data_url = Routes.account_accounting_path() + '/rental_income_summary?year=' + year;
        var data = summary_data;
        if(year in data) { callback(data); return; }        
        $.getJSON(data_url, function(r) {
            if(r.success) {
                delete r.success;
                data[year] = r;
                callback(data);
            } else {
                console.log('error fetching summary data');
                return false;
            }
        });        
        summary_data = data;
    }
    
    function refresh_summaries(year, month) {
        fetch_summary_data(year, month, function(data){
            set_monthly_total(year, month, data[year].monthly[month - 1].total.toFixed(2) || 0.00);
            set_yearly_total(year, data[year].ytd.total.toFixed(2) || 0.00);            
        });
    }
    
    // Set initial state of dates
    set_year(url_year);
    set_month(url_month);
    refresh_summaries(get_year(), get_month());

    // Handle year changes
    function subtractYear() {
        if(get_year() <= 2018) { return; }
        set_year(get_year() - 1);
        refresh_summaries(get_year(), get_month());
    }

    function addYear() {
        var now_year = (new Date).getFullYear();
        var now_month = (new Date).getMonth() + 1;
        var new_year = get_year() + 1;
        if(new_year > now_year) { return; }
        if(new_year == now_year && get_month() > now_month) {
            set_month(now_month);
        }
        set_year(new_year);
        refresh_summaries(new_year, get_month());
    }

    // Handle month changes
    month_selector.on('click', function(e) {
        e.preventDefault();
        var m = parseInt($(this).val());
        if(get_year() == (new Date).getFullYear() && m > (new Date).getMonth() + 1) {
            return; // can't be month in future
        }
        set_month(m);
        refresh_summaries(get_year(), m);
    });
}


  ///Dynamic Receipt  
  /** Objective is to give the customer a receipt the can edit and add to allowing them to better invoice their customer *
  if (document.getElementById("invoice")){

    //Creates a new row
      var newRow = '<tr class="line-item"><td id="product_info"><a class="control removeRow" href="#">x</a>Product Name</td><td id="item_type">Type</td> <td id="date_info">Date</td><td class="line-cost line-sub money">0.00</td><td class="line-cost line-dw money">0.00</td><td class="line-cost line-tax money">0.00</td><td class="line-total money" contenteditable=false></td></tr>';


      $('.newRow').on('click',function(e){
        $('.invoicelist-body tbody').append(newRow);
        e.preventDefault();
      });

    //Removes Row
      $('body').on('click','.removeRow',function(e){
        $(this).closest('tr').remove();
        e.preventDefault();
      });


    /// Calculates Row
      function calculate_lines() {
      $('tr').each(function () {
          var sum = 0;
          $(this).find('.line-cost').each(function () {
              var line_item = $(this).text();
              if (!isNaN(line_item) && line_item.length !== 0) {
                  sum += parseFloat(line_item);
              }
          });
          $(this).find('.line-total').html(sum.toFixed(2));
      });
      }

     /// Calculates Subtotal
      function calculate_sub(){
      var sum = 0;
      $('tr').find('.line-sub').each(function () {
          var line_sub = $(this).text();
          if (!isNaN(line_sub) && line_sub.length !== 0) {
              sum += parseFloat(line_sub);
          }
      });

      $('.full-subtotal').html(sum.toFixed(2));

      }


    /// Calculates DW
      function calculate_dw(){
      var sum = 0;
      $('tr').find('.line-dw').each(function () {
          var line_dw = $(this).text();
          if (!isNaN(line_dw) && line_dw.length !== 0) {
              sum += parseFloat(line_dw);
          }
      });
      $('.full-dw').html(sum.toFixed(2));

      }


    //// Calculates Tax Line  | NOTE: Does Not pull in tax percentage 
      function calculate_tax(){
      var sum = 0;
      $('tr').find('.line-tax').each(function () {
          var line_tax = $(this).text();
          if (!isNaN(line_tax) && line_tax.length !== 0) {
              sum += parseFloat(line_tax);
          }
      });
      $('.full-tax').html(sum.toFixed(2));
      }
    //// Calculates Total
      function calculate_total(){
      var sum = 0;
      $('tr').find('.line-total').each(function () {
          var line_total = $(this).text();
          if (!isNaN(line_total) && line_total.length !== 0) {
              sum += parseFloat(line_total);
          }
      });

      $('.total-price').html(sum.toFixed(2));

      }

    /// Calculates total Paid
      function paid_total(){
      var sum = 0;
      $('tr').find('.paid-amount').each(function () {
          var paid_amount = $(this).text();
          if (!isNaN(paid_amount) && paid_amount.length !== 0) {
              sum += parseFloat(paid_amount);
          }
      });

      $('.total-paid').html(sum.toFixed(2));

      }



    /* Calls all calculate functions
      function calculate(){
      calculate_lines();
      calculate_sub();
      calculate_tax();
      calculate_dw();
      calculate_total();
      paid_total();
      total_due_to_sdn();

      }
      calculate();

    /// Runs function on editing invoice
      $('#invoice').on('keyup',function(){
      calculate();
      });


    /// Runs function when removing a line, with a time delay
      $( ".removeRow" ).click(function() {
      setTimeout( function(){ 
      calculate();
      }  , 200 );

      });

      */

     if (document.getElementById("invoice")){
      /// Hides warning when correct
     if ( document.getElementById("balance_due").innerHTML == 0 )  { 
     $('#inaccurate').hide();
        }

    }


// My Account - Inventory storage status update
 if(document.getElementsByClassName('inventory_status_form').length > 0) {

     function change_inventory_status(product_id, status, before, after) {
	 return new Promise(function(resolve, reject) {
	     $.ajax({
		 url: update_inventory_status_path(),
		 type: 'POST',
		 data: { product_id: product_id, status: status },
		 beforeSend: before,
		 complete: after,
		 success: function(response) {
		     resolve(response);
		 },
		 error: function(response) {
		     reject(response);
		 }
	     });
	 });
     }
     
     $(function(){
         Array.from(document.getElementsByClassName("inventory_status_form")).forEach(function(form) {

	     var select = $('select[name=status]', form).first();

	     // Save original state in case of error and store details for modal
	     select.data('original_status', select.val());
	     select.data('product_id', $('input[name=product_id]', form).first().val());
	     select.data('storage_rate', $(form).data('storage-rate'));

	     select.change(function(e) {
		 var old_status = $(this).data('original_status');
		 var new_status = $(this).val();
		 var product_id = $(this).data('product_id');
		 var storage_rate = $(this).data('storage_rate');

		 // Fires the change_inventory_status global method and handles UI loaders/alerts
		 function change_status() {
		     $('.alert-dismissable').remove();
		     var spinner = $('<div class="spinner-border spinner-border-sm" role="status"></div>');
		     var alert = $('<div class="alert mt-2 alert-dismissable"><button type="button" class="close" data-dismiss="alert" aria-label="Close"><span aria-hidden="true">&times;</span></button></div>');

		     change_inventory_status(product_id, new_status, function() {
                         select.addClass('d-none');
                         spinner.insertAfter(select.parent());
		     }, function() {
			 spinner.remove();
		     }).then(function(response) {
			 alert.append(response.message);
			 select.removeClass('d-none');
			 if(response.success) {
			     alert.addClass('alert-success');
			 } else {
			     alert.addClass('alert-danger');
			     select.val(old_status);
			 }
			 alert.insertAfter(select.parent());
		     }, function(response) {
			 alert.append('An error occurred.');
			 select.val(old_status);
			 select.removeClass('d-none');
			 alert.addClass('alert-danger');
			 alert.insertAfter(select.parent());
		     });
		 }
		 
		 if(new_status == 'Private') {
		     var modal = $('#private_alert');

		     $('#item_number', modal).html(product_id);
		     $('#storage_price', modal).html(storage_rate);
		     $('#30_day_storage_price', modal).html((storage_rate * 30).toFixed(2));
		     modal.modal();
		     
		     $('#make_private', modal).click(function() {
			 change_status();
			 $(this).unbind('click');
			 $(modal).unbind('hide.bs.modal');			 
		     });

		     $(modal).on('hide.bs.modal', function(e) {
			 select.val(old_status);
			 $(this).unbind('hide.bs.modal');
			 $('#make_private', modal).unbind('click');
		     });
		 } else {
		     change_status();
		 }
	     });
	 });
     });
 }


/// Slider for Filters
if (document.getElementsByClassName("range-slider")){
  function getVals(){
    // Get slider values
    var parent = this.parentNode;

      var slide_min = parent.getElementsByTagName("input")[0].value;
      var slide_max = parent.getElementsByTagName("input")[1].value;
    // Neither slider will clip the other,
    if(+slide_min > +slide_max){ 
        var new_min = slide_max; 
        slide_max = slide_min; 
        slide_min = new_min; 
      }
    parent.getElementsByClassName("rangeValues_min")[0].value = slide_min;
    parent.getElementsByClassName("rangeValues_max")[0].value = slide_max;
  }

  window.onload = function(){
    //  Sliders
    var sliderSections = document.getElementsByClassName("range-slider");
        for( var x = 0; x < sliderSections.length; x++ ){
          var sliders = sliderSections[x].getElementsByTagName("input");
          for( var y = 0; y < sliders.length; y++ ){
            if( sliders[y].type ==="range" ){
              sliders[y].oninput = getVals;
              // Default Calu
              sliders[y].oninput();
            }
          }
        }
  }
}



if (document.getElementById("street-view")) { 

    var street = document.getElementById('stage-street').innerHTML;
    street = street.replace(/\s+/g, '+');
    var city  = document.getElementById('stage-city').innerHTML;
    city = city.replace(/\s+/g, '+');
    var state = document.getElementById('stage-state').innerHTML;
    var keyapi ="AIzaSyBtQPkfuUVc4Vx6JKJNWLGhcSPCjdkzmzk";
    var lat;
    var long;
    var address =street+","+city+","+state;
    var map_api = "https://maps.googleapis.com/maps/api/geocode/json?address="+address+"&key="+keyapi;

    $.getJSON(map_api, function(location){
        if (location.results.length == 0 ) {
            var streetview = "https://www.google.com/maps/embed/v1/view?key=" + keyapi + "&center=37.0902,-95.7129&zoom=15";
        } else {
            lat = location.results[0].geometry.location.lat;
            long = location.results[0].geometry.location.lng;
            var streetview = "https://www.google.com/maps/embed/v1/view?key=" + keyapi + "&center=" + lat + ',' + long + "&zoom=15";
        }
        $('#street-view').attr('src',streetview);
    });

 
}
