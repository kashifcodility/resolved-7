document.addEventListener("DOMContentLoaded", function(event) {
    if(document.getElementById('review_modal') ){
        function add_review() {    
            let edit_order_btns_stage = [...document.querySelectorAll('.add_review_btn')];
            if(edit_order_btns_stage.length) {
                edit_order_btns_stage.forEach(button =>{
                    button.addEventListener('click', function(e){
                        e.preventDefault();
                        let p_id = document.getElementById('id');
                        let p_name = document.getElementById('name');
                        let image = document.getElementById('img');
                        let product_id = document.getElementById('product');
                        let order_id = document.getElementById('order');                        
                        let id = button.getAttribute('product_id');
                        let name = button.getAttribute('product_name');
                        let src = button.getAttribute('url');
                        product_id.value = id;
                        p_name.textContent = name;
                        // p_id.textContent = id;
                        image.src = src;
                        let pathname = window.location.pathname;
                        order_id.value = pathname.split('/').pop();
                    })
                })
            }
        }
        add_review()
    }   
})




