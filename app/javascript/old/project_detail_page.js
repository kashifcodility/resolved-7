import { project_update_product_room_path } from 'routes';

document.addEventListener("DOMContentLoaded", function(event) {
    // GLOBAL PAGE WITH FILTERS gpwf
    function global_page_with_filters(){
        let headers_to_click = document.querySelectorAll('.header_to_click');
        const mediaQuery = window.matchMedia('(max-width: 700px)')
        if (mediaQuery.matches) {
            headers_to_click.forEach(item =>{
                item.classList.remove("div_show");
            })
        }
        headers_to_click.forEach(header =>{
            header.addEventListener('click', function(){
                header.classList.toggle("div_show");
            })
        })
    }
    global_page_with_filters()
    // GLOBAL PAGE WITH FILTERS gpwf ENDS


    // CONFIRMATION POPUP BEFORE REMOVING ITEM
    function remove_item_btn_activate() {
        let remove_item_button = document.querySelectorAll('.remove_item_btn_container .remove_item_button');
        remove_item_button.forEach(button => {
            button.addEventListener('click', function(e) {
                let form_to_submit = this.nextElementSibling;                
                $("#remove_item_confirmation").modal('show');    
                let btn_yes = document.querySelector('.yes_remove');
                btn_yes.addEventListener('click', function submit_form() {
                    let lineId = form_to_submit.querySelector('#line_id').value;
                    let binNameField = form_to_submit.querySelector(`#bin_name_${lineId}`);
                    let bin_name = document.getElementById('autocomplete_input').value;
                    if (bin_name) {
                        document.getElementById(binNameField.id).value = bin_name;
                    }                     
                    form_to_submit.submit(); 
                    btn_yes.removeEventListener('click', submit_form, false);
                })
            })
        })
    }
    remove_item_btn_activate()
    
    // END

    // CONFIRMATION POPUP BEFORE CANCEL THE ORDER
    function cancel_btn_activate(){
        let cancel_order_btn = document.getElementById('cancel_order_btn');
        cancel_order_btn.addEventListener('click', function(e){
            e.preventDefault();
            let link = this.getAttribute("href")
            $("#cancel_order_confirmation").modal('show');

            let btn_yes = document.querySelector('.yes_cancel');
            btn_yes.addEventListener('click', function submit_form(){
                window.open(link, "_self");
            })
        })
    }
    if(document.getElementById('cancel_order_btn')){
        cancel_btn_activate()
    }
    // END


    // ROOM ASSIGNING
    const room_container = document.querySelector('.all_ric_components')
    function activate_room_selection(){
        let room_btns = document.querySelectorAll(".room_selection");
        room_btns.forEach(btn => {
            let product_line_id = btn.getAttribute('product_line_id')
            let room_id = btn.getAttribute('room_id')
            let order_id = btn.getAttribute('order_id')
            btn.addEventListener('click', ()=>{
                asign_room(product_line_id, room_id, order_id)
            })
        })
    }
    function asign_room (product_line_id, room_id, order_id ){
        $(".small_spinner_container").css("display", "flex");
        $("#all_rooms_components").html("");
        const data = {
            "line_id" :product_line_id,
            "room_id" :room_id,
            "order_id" :order_id,
        }
        let alert = document.createElement('div');
		alert.classList.add('alert', 'alert-danger');
		alert.innerText = 'Error loading products.';

        $.ajax({
            async: false,
            url: project_update_product_room_path(order_id),
            data: JSON.stringify(data),
            headers: {
                'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')  // Adding CSRF token to request headers
            },
            type: 'post',
            dataType: 'json',
            contentType: 'application/json; charset=utf-8',
            success: function (partial) {
                $(".small_spinner_container").css("display", "none");
                $("#all_rooms_components").html(partial["html"]);
                activate_room_selection()
                remove_item_btn_activate()
            },		    
            error: function() {
                body.appendChild(alert);
            }
        });
    }
    activate_room_selection();
    // END


    // ROOM FILTERS
    // A) check localStorage
    // if( remove_grouping_checkbox === true){ removing grouping }
        // 1. grab all items with class ric
        // 2. hide div with class grouped_items
        // 3. create new room and loop through ric list creating items
        // 4. activate events
    // if( hide_returned_items_checkbox === true){ hiding returned items }
        // 1. copy innerHTML of grouped_items into ungrouped_items
        // 2. grab all items with class returned_item and make them display none
        // 3. activate events

    // B) 
    // add event listeners to checkboxes
    // if (hide_returned_items_checkbox === false)
        // function return_default():
            // ungrouped_items div - display none
            // grouped_items - display block
            // activate events

    // if( remove_grouping_checkbox === false){ hiding returned items }
        // function return_default():



    if(document.getElementById('hide_returned_items_checkbox')){
        let hide_returned_items_checkbox = document.getElementById('hide_returned_items_checkbox');
    
        function activate_room_filters(){
            hide_returned_items_checkbox.addEventListener('change', hide_returned_items )
        }

        function hide_returned_items() {
            const returned_items_list = document.querySelectorAll('.returned_item');
            if(this.checked){
                console.log("HIDING RETURNED ITEMS");
                returned_items_list.forEach(item => {
                    item.style.display = "none";
                })
            }else{
                console.log("SHOWING RETURNED ITEMS");
                returned_items_list.forEach(item => {
                    item.style.display = "flex";
                })
            }
        }

        activate_room_filters()
        // END
    }
})