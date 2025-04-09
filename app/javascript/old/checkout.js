document.addEventListener("DOMContentLoaded", function(event) {

    // CLOSE NOTIFICATION
    let close_notification_btns = document.querySelectorAll('.img_close');
    close_notification_btns.forEach(item => {
        item.addEventListener('click', function(){
            this.parentNode.style.display = "none";
        })
    })


    // REVIEW ITEMS PAGE > DELETE ITEM > Adding spinner
    function delete_item_loader() {
        const delete_btns = document.querySelectorAll('.trash_item');
        delete_btns.forEach( del_btn => {
            del_btn.addEventListener('click', function(e){
                start_loader(this)
            })
        })
        function start_loader(del_btn) {
            del_btn.classList.add("deleting");
        }
    }
    delete_item_loader()

  


    // IF NEW CONSTRUCTION CHECKED
    if(document.querySelector("#new_construction_form")){
        let new_construction_checkbox = document.querySelector("#new_construction_checkbox");
 
        new_construction_checkbox.addEventListener('change', function(){
            toggle_new_construction_fields(new_construction_checkbox);
        })

        toggle_new_construction_fields(new_construction_checkbox);

        function toggle_new_construction_fields(elem) {
            let new_construction_fields = document.querySelectorAll('#new_construction_form input.required_field');
            let autocomplete_field = document.querySelector("#autocomplete");
            let new_construction_form = document.querySelector("#new_construction_form");
            let elems_to_hide = document.querySelectorAll('.hide_if_new_construction')

            if(elem.checked){
                autocomplete_field.style.display = "none";
                new_construction_form.style.display = "block";
                elems_to_hide.forEach(el => { el.style.display = "none";})
                new_construction_fields.forEach(input => {
                    input.setAttribute("required", "");
                });
                autocomplete_field.addEventListener("focus", geolocate())
                document.getElementById('full_address').focus();
            }else{
                new_construction_form.style.display = "none";
                elems_to_hide.forEach(el => { el.style.display = "block";})
                autocomplete_field.style.display = "block";
                new_construction_fields.forEach(input => {
                    input.removeAttribute("required");
                });
            }            
        }
    }

    // DELIVERY OPTIONS LOGIC
    $('#delivery_fields').hide()
    $('#pickup_fields').hide()
    
    let shipping_options = document.querySelector('#shipping_method')
    if (shipping_options) {
        shipping_options.addEventListener('change', function(){
            handle_delivery_option(shipping_options);
        })
        handle_delivery_option(shipping_options);
    }

    function handle_delivery_option(elem){
        switch(elem.value){
            case 'delivery':
                $('#pickup_fields .required_field').prop('required', false);
                $('#pickup_fields').hide()
                $('#delivery_fields .required_field').prop('required', true);
                $('#delivery_fields').show()
                break;
            case 'pickup':
                $('#delivery_fields .required_field').prop('required', false);
                $('#delivery_fields').hide()
                $('#pickup_fields .required_field').prop('required', true);
                $('#pickup_fields').show()
                break;
        }
    }
    // DELIVERY OPTIONS LOGIC ENDS


    // Bootstrap Datepicker ( https://www.nicesnippets.com/blog/bootstrap-datepicker-disabled-specific-dates-and-saturdaysunday )
    $(function() {
        let today = new Date();
        let formattedToday = String(today.getMonth() + 1).padStart(2, '0') + '-' + String(today.getDate()).padStart(2, '0') + '-' + today.getFullYear();
        let nextDay = new Date(today);
        nextDay.setDate(today.getDate() + 1);
        let formattedNextDay = String(nextDay.getMonth() + 1).padStart(2, '0') + '-' + String(nextDay.getDate()).padStart(2, '0') + '-' + nextDay.getFullYear();

        // Set in view
        // var datesEnabled = [];
        // var datesDisabled = ['2019-11-28', '2019-11-29'];
     
        function formatDate(d) {
          var day = String(d.getDate())
          //add leading zero if day is is single digit
     
          if (day.length == 1)
            day = '0' + day
          var month = String((d.getMonth()+1))
          //add leading zero if month is is single digit
          if (month.length == 1)
            month = '0' + month
          return d.getFullYear() + '-' + month + "-" + day;
        }
     
        // TODO: De-duplicate
        $('#pickup_date').datepicker({
            format: 'mm-dd-yyyy',
            startDate: today
            // daysOfWeekDisabled: [6,7],
            // beforeShowDay: function(date){
            //     var dayNr = date.getDay();
            //     let dmy = date.getFullYear() + "-" + (date.getMonth() + 1) + "-" + date.getDate();
            //     if(date <= (new Date(datesPickupMin + ' 00:00:00'))) {
            //         return false;
            //     }
            //     if(datesDisabled.indexOf(dmy) != -1){
            //         return false;
            //     }
            //     if (dayNr==0  ||  dayNr==6){
            //         if (datesEnabled.indexOf(formatDate(date)) >= 0) {
            //             return true;
            //         }
            //         return false;
            //     }
            //     if (datesDisabled.indexOf(formatDate(date)) >= 0) {
            //         return false;
            //     }
            //     return true;
            // }
        }).on('changeDate', function(e) {
            // Get the selected date
            const selectedDate = e.format();
            if (selectedDate === formattedToday || selectedDate === formattedNextDay){
                $('#largeModal').modal('show');
            }
            else{
                document.getElementById("rush_order").value = 0;   
            }
          });

        $('#delivery_date').datepicker({
            format: 'mm-dd-yyyy',
            startDate: today
            // daysOfWeekDisabled: [6,7],
            // beforeShowDay: function(date){
            //     var dayNr = date.getDay();
            //     let dmy = date.getFullYear() + "-" + (date.getMonth() + 1) + "-" + date.getDate();
            //     if(date <= (new Date(datesDeliveryMin + ' 00:00:00'))) {
            //         return false;
            //     }
            //     if(datesDisabled.indexOf(dmy) != -1){
            //         return false;
            //     }
            //     if (dayNr==0  ||  dayNr==6){
            //         if (datesEnabled.indexOf(formatDate(date)) >= 0) {
            //             return true;
            //         }
            //         return false;
            //     }
            //     if (datesDisabled.indexOf(formatDate(date)) >= 0) {
            //         return false;
            //     }
            //     return true;
            // }
        }).on('changeDate', function(e) {
            // Get the selected date
            const selectedDate = e.format();
            if (selectedDate === formattedToday || selectedDate === formattedNextDay){
              $('#largeModal').modal('show');
            }
            else{
                document.getElementById("rush_order").value = 0;   
            }
          });       
     });
     // Bootstrap Datepicker ENDS


    // CHANGE PAYMENT METHOD
    $('#new_card_fields').hide()
    $('#charge_account_fields').hide()
    
    let payment_method = document.querySelector('#payment_method')
    if(payment_method){
        payment_method.addEventListener('change', function(){
            handle_payment_method(payment_method);
        })
    
        handle_payment_method(payment_method);
    }
    
    function handle_payment_method(elem){
        let new_card_fields = document.querySelector('#new_card_fields')
        let charge_account_fields = document.querySelector('#charge_account_fields')

        switch(elem.value){
            case 'charge_account': // Charge account
                $('#new_card_fields .required_field').prop('required', false);
                $('#new_card_fields').hide();
                $('#charge_account_fields .required_field').prop('required', true);
                $('#charge_account_fields').show();
                break;
            case 'new': // New card
                $('#charge_account_fields .required_field').prop('required', false);
                $('#charge_account_fields').hide();
                $('#new_card_fields .required_field').prop('required', true);
                $('#new_card_fields').show();
                break;
            default: // Saved card selected
                $('#charge_account_fields .required_field').prop('required', false);
                $('#charge_account_fields').hide();
                $('#new_card_fields .required_field').prop('required', false);
                $('#new_card_fields').hide();
                break;
        }
    }
    // CHANGE PAYMENT METHOD ENDS

})