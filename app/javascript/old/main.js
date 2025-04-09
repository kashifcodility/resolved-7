



function getLocation() {

  if (navigator.geolocation) {  
      navigator.geolocation.watchPosition(showPosition);
      } else {
      x.innerHTML = "Geolocation is not supported by this browser.";
  }

}

function showPosition(position) {
    
    const api_url = "https://us1.locationiq.com/v1/reverse.php?key=aa874ee49a56f4&lat=" + position.coords.latitude + "&lon=" + position.coords.longitude +"&format=json";

    async function getZip(){
        const response = await fetch(api_url);
        var data =  await response.json();
        var state = data.address.state;
        var zip = parseInt(data.address.postcode);     
        var azState = ["Arizona", "California", "Texas", "Utah","New Mexico","Nevada","Colorado","Wyoming"];
        var everettZip =[98012,98020,98021,98026,98036,98037,98043,98087,98201,98203,98204,98205,98207,98208,98220,98221,98223,98225,98226,98229,98232,98233,98236,98239,98244,98249,98252,98253,98258,98260,98270,98271,98272,98273,98274,98275,98277,98278,98282,98284,98290,98292,98294,98296,98340,98342,98346,98364,98365,98370,98392,98011,98028,98155,98133,98177,98125,98115,98103,98117,98107,98105,98195,98358,98257,98262];

        if (azState.includes(state)==true) {
            window.location.replace("/session/change_location/25");
            console.log ('Phoenix');
        } 
        else if ((everettZip.includes(zip)==true) || zip>98200 && zip<989){
            window.location.replace("/session/change_location/24");
            console.log ('Everett');
        } 
        else{
            window.location.replace("/session/change_location/23");
            console.log ('Kirkland');
        }
    }

    getZip(state, zip);

}
