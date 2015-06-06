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
 * @register { -> void}
 */
function test() {

}