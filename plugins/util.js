/**
 * @register {string , ( int -> void ) -> void}
 */
function register_line_handler(type, callback) {
    $('#src-container').on(type, 'li', function () {
        var num = $(this).index();
        // value is zero based
        callback(num + 1);
    });
}
/**
 * @register {int, string, string -> void}
 */
function add_warning(line, title, text) {
    var elem = $('ol.linenums').children('li').eq(line - 1);
    elem.addClass('warn');
    var oldtitle = elem.attr('title');
    if(oldtitle && oldtitle !== ''){
        oldtitle += '\n\n';
    }else{
        oldtitle = "";
    }
    elem.attr('title', oldtitle + title + '\n' + text);
}

/**
 * @register { string -> void}
 */
function pushState(str){
    history.replaceState({}, "", str);
}