
$(document).ready(function(){

    // ONE TIME POPUP  ABOUT CLOSING PHENIX LOCATION
    if(sessionStorage.getItem('#closing_phenix') !== 'false'){
        if($('#closing_phenix')){
            $("#closing_phenix").modal('show');
            $("#closing_phenix").on("hidden.bs.modal", function () {
                sessionStorage.setItem('#closing_phenix', 'false')
            });
        }
    }

    // CLOSE WARNING NOTIFICATION ON THE USER ACCOUNT SIDEBAR
    if($('#closing_phenix2')){
        if(sessionStorage.getItem('#closing_phenix2') !== 'false'){
            $('.close_warning').on('click', function(){
                $('#closing_phenix2').css( "display", "none" );
                sessionStorage.setItem('#closing_phenix2', 'false')
            })
        }else{
            $('#closing_phenix2').css( "display", "none" );
        }
    }

    // CLEAR STORAGE
    if($('#logout_button').length) {
        document.querySelector('#logout_button').addEventListener('click', function(){
            sessionStorage.clear();
        })
    }

})





