function is_ios_safari() { 
    return navigator.vendor && navigator.vendor.indexOf('Apple') > -1 &&navigator.userAgent && navigator.userAgent.indexOf('CriOS') == -1 && navigator.userAgent.indexOf('FxiOS') == -1;
}