document.addEventListener("DOMContentLoaded", function(event) {

    // EDIT PROJECT NAME
    if(document.getElementById('edit_stage_info') ){
        function edit_stage_info() {    
            let edit_order_btns_stage = [...document.querySelectorAll('.edit_stage_info_btn')];
            let form_title_stage = document.getElementById('form_title_project_id1')
            let form_stage = document.getElementById('edit_stage_info_form')
            
            if(edit_order_btns_stage.length) {
                edit_order_btns_stage.forEach(button =>{
                    button.addEventListener('click', function(e){
                        e.preventDefault();
                        console.log('find..............')
                        let first_name = document.getElementById('f_name');
                        let last_name = document.getElementById('l_name');
                        let project_phone = document.getElementById('stage_phone');
                        let project_address = document.getElementById('stage_address');
                        let project_home_type = document.getElementById('stage_home_type');
                        let project_levels = document.getElementById('stage_levels');
                        let project_instructions = document.getElementById('stage_instructions');
                        let link_first_name = button.getAttribute('stage_first_name');
                        let link_last_name = button.getAttribute('stage_last_name');
                        let link_phone = button.getAttribute('stage_phone');
                        let link_address = button.getAttribute('stage_address');
                        let link_home_type = button.getAttribute('stage_home_type');
                        let link_levels = button.getAttribute('stage_levels');
                        let link_instructins = button.getAttribute('stage_instructins');
                        let project_id = button.getAttribute('project_id');
                       
                        first_name.value = link_first_name;
                        last_name.value = link_last_name;
                        project_home_type.value = link_home_type;
                        project_phone.value = link_phone;
                        project_address.value = link_address;
                        project_levels.value = link_levels;
                        project_instructions.value = link_instructins;
                        form_title_stage.textContent = `#${project_id}`;
                        form_stage.action = Routes.update_project_path(project_id);
                    })
                })
            }
        }
        edit_stage_info()
    }
    
    
})




