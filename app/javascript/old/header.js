// CART SIDEBAR PREVIEW > DELETE ITEM > Adding spinner
$(".cart_icon").on("click", function () {
    const delete_btns = document.querySelectorAll('.trash_item');
    if(delete_btns.length > 0){
        delete_btns.forEach( del_btn => {
            del_btn.addEventListener('click', function(e){
                start_loader(this)
            })
        })
        function start_loader(del_btn) {
            del_btn.classList.add("deleting");
        }
    }
});


document.addEventListener("DOMContentLoaded", function(event) {
    function focusInput() {
        document.getElementById("search-input").focus();
    }
    const mediaQuery = window.matchMedia('(max-width: 500px)')
    // FOR IOS USERS
    if(is_ios_safari() ){
        if (mediaQuery.matches) {
            if(document.querySelectorAll('.ios_space')){
                let all_spaces = document.querySelectorAll('.ios_space');
                all_spaces.forEach(item => {
                    item.style.display = "block";
                })
            }
        }
        if(document.querySelectorAll('.ios_space_for_safari')){
            let all_safari_spaces = document.querySelectorAll('.ios_space_for_safari');
            all_safari_spaces.forEach(space => {
                space.style.display = "block";
            })
        }

    }else{
        if(document.querySelectorAll('.ios_space')){
            let all_spaces = document.querySelectorAll('.ios_space');
            all_spaces.forEach(item => {
                item.style.display = "none";
            })
        }
        if(document.querySelectorAll('.ios_space_for_safari')){
            let all_safari_spaces = document.querySelectorAll('.ios_space_for_safari');
            all_safari_spaces.forEach(space => {
                space.style.display = "none";
            })
        }
    }
    // END 

    let mobile_os = get_mobile_operation_system();
    if(mobile_os === " iOS"){
        if(is_ios_safari() ){
            return true;
        }else{
            if (mediaQuery.matches) {
                if(document.querySelectorAll('.ios_chrome_space')){
                    let all_spaces = document.querySelectorAll('.ios_chrome_space');
                    all_spaces.forEach(item => {
                        item.style.display = "block";
                    })
                }
            }else{
                if(document.querySelectorAll('.ios_chrome_space')){
                    let all_spaces = document.querySelectorAll('.ios_chrome_space');
                    all_spaces.forEach(item => {
                        item.style.display = "none";
                    })
                }
            }
        }
    }


    //  Determine the mobile operating system.
    //  This function returns one of 'iOS', 'Android', 'Windows Phone', or 'unknown'.
    function get_mobile_operation_system() {
        var userAgent = navigator.userAgent || navigator.vendor || window.opera;
    
        // Windows Phone must come first because its UA also contains "Android"
        if (/windows phone/i.test(userAgent)) {
            return "Windows Phone";
        }
    
        if (/android/i.test(userAgent)) {
            return "Android";
        }
    
        // iOS detection from: http://stackoverflow.com/a/9039885/177710
        if (/iPad|iPhone|iPod/.test(userAgent) && !window.MSStream) {
            return "iOS";
        }
    
        return "unknown";
    }


    // SEARCH PANEL OPEN - CLOSE 
    function search_panel(){
        let open_search_container_btn = document.querySelector('#open_search_container_btn');
        let close_search_container_btn = document.querySelector('#close_search_container_btn');
        let searchbar_container = document.querySelector('#searchbar_container');
        let input_field = document.querySelector('#input_field > input');


        open_search_container_btn.addEventListener('click', function(){
            searchbar_container.style.display = "flex";
            focusInput()
        })

        close_search_container_btn.addEventListener('click', function(){
            searchbar_container.style.display = "none";
            input_field.value = "";
        })
    }
    search_panel()
    // END


    // SHOW HEADER DROPDOWN 
    function show_header_dropdown(){
        // let show_shop_dropdown = document.querySelector(".show_shop_dropdown");
        let header_dropdown = document.querySelector(".header_dropdown");
        let top_header = document.querySelector("#top_header");
        let shop_dropdown_arrow = document.querySelector(".shop_dropdown_arrow");
    
        // show_shop_dropdown.addEventListener('click', function(){
        //     showDropDown(header_dropdown);
        // })
        // No need for above piece of code as show_shop_dropdown has been removed
    
        function showDropDown(elem){
            if(elem.classList.contains('show_dropdown')){
                elem.classList.remove('show_dropdown');
                shop_dropdown_arrow.classList.remove('rotate_arrow')
            }else{
                elem.classList.add('show_dropdown');
                shop_dropdown_arrow.classList.add('rotate_arrow')
            }
            window.addEventListener('click', function close_dropdown(e){   
                if(document.getElementById('dropdown_container').contains(e.target) || document.getElementById('navbar').contains(e.target)){
                  return false
                } else{
                    window.removeEventListener('click', close_dropdown, false)
                    if(header_dropdown.classList.contains('show_dropdown')){
                        header_dropdown.classList.remove('show_dropdown');
                        shop_dropdown_arrow.classList.remove('rotate_arrow');
                    }
                }
            });
        }

    }
    show_header_dropdown()
    // END

    // SIDE CONTAINER - MOBILE NAVIGATION
    function menu_dropdown(){
        let acc1 = document.getElementsByClassName("menu_item");
        let j;
        for(j = 0; j < acc1.length; j++){
            acc1[j].addEventListener("click", function(){
                this.classList.toggle("active_menu")
                let menu_panel = this.nextElementSibling;
                if (menu_panel.style.display === "block"){
                    menu_panel.style.display = "none";
                } else{
                    menu_panel.style.display = "block";
                }
            });
        }

        let acc2 = document.getElementsByClassName("submenu_item");
        let k;
        for(k = 0; k < acc2.length; k++){
            acc2[k].addEventListener("click", function(){
                this.classList.toggle("active_submenu")
                let submenu_panel = this.nextElementSibling;
                if (submenu_panel.style.display === "block"){
                    submenu_panel.style.display = "none";
                } else{
                    submenu_panel.style.display = "block";
                }
            });
        }
    }

    if ($('.inventory-drop').data('logged-in')) {
        $('.inventory-drop').mouseenter(function() {
            $('.header_dropdown').addClass('show_dropdown');
          })
          $('.new_layout').mouseleave(function() {
            $('.header_dropdown').removeClass('show_dropdown');
          })
    }
    menu_dropdown()
    // END

        
})

