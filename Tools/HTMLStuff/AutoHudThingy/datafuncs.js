/*
** JSON functions
*/
var validateJSON = function (dataString) {
    try {
        JSON.parse (dataString);
    } catch (e) {
        return false;
    }
    return true;
};

/*
** Misc functions
*/
escapeHTMLLeft = [
    '"',
    '\'',
    '<',
    '>'
];
escapeHTMLRight = [
    '&quot;',
    '&apos;',
    '&lt;',
    '&gt;'
];
var escapeHTML = function (data) {
    escaped = data;

    for (var i = 0; i < escapeHTMLLeft.length; i++) {
        escaped = escaped.replace (escapeHTMLLeft [i], escapeHTMLRight [i], 'g')
    }

    return escaped;
};

var HttpClient = function () {
    this.get = function (aUrl, aCallback) {
        var anHttpRequest = new XMLHttpRequest ();
        anHttpRequest.onreadystatechange = function () { 
            if (anHttpRequest.readyState == 4 && anHttpRequest.status == 200)
                aCallback (anHttpRequest.responseText);
        }

        anHttpRequest.open ("POST", aUrl, true);            
        anHttpRequest.send (null);
    }
}