document.addEventListener("DOMContentLoaded", function(event) {

    // EDIT PROJECT NAME
    if(document.getElementById('project_listing_page') || document.getElementById('project_detail_page') ){
        
        function edit_project_name() {    
            let edit_order_btns = [...document.querySelectorAll('.edit_order_btn')];
            let form_title = document.getElementById('form_title_project_id')
            let form = document.getElementById('edit_proj_name_form')

            if(edit_order_btns.length) {
                edit_order_btns.forEach(button =>{
                    button.addEventListener('click', function(e){
                        e.preventDefault();
     
                        let input_field = document.getElementById('project_name');
                        let project_contact = document.getElementById('project_contact');
                        let project_phone = document.getElementById('project_phone');
                        let project_email = document.getElementById('project_email');
                        let project_address = document.getElementById('project_address');
                        let project_delivery_call = document.getElementById('shipping_method');
                        let project_home_type = document.getElementById('project_home_type');
                        let project_levels = document.getElementById('project_levels');
                        let project_instructions = document.getElementById('project_instructions');
                        let project_delivery_date = document.getElementById('project_delivery_date');
                        // input_field.value = "";

                        let project_name = button.getAttribute('project_name');
                        let link_contact = button.getAttribute('link_contact');
                        let link_phone = button.getAttribute('link_phone');
                        let link_email = button.getAttribute('link_email');
                        let link_address = button.getAttribute('link_address');
                        let link_delivery_call = button.getAttribute('link_delivery_call');
                        let link_home_type = button.getAttribute('link_home_type');
                        let link_levels = button.getAttribute('link_levels');
                        let link_instructins = button.getAttribute('link_instructins');
                        let link_delivery_date = button.getAttribute('link_delivery_date');
                        let project_id = button.getAttribute('project_id');
                        input_field.value = project_name;
                        project_contact.value = link_contact;
                        project_email.value = link_email;
                        project_delivery_call.value = link_delivery_call;
                        project_home_type.value = link_home_type;
                        project_phone.value = link_phone;
                        project_address.value = link_address;
                        project_levels.value = link_levels;
                        project_instructions.value = link_instructins;
                        project_delivery_date.value = link_delivery_date;
                        form_title.textContent = `#${project_id}`;
                        form.action = Routes.update_project_path(project_id);
                    })
                })
            }
        }
        edit_project_name()
    }
    // EDIT PROJECT NAME ENDS
    
})




