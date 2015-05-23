/**
 * @register {string -> void}
 */
function render(dot) {
    console.log(dot);
    var g = graphlibDot.read(dot);
    console.log(g);

    var render = new dagreD3.render();
    // Set up an SVG group so that we can translate the final graph.
    var svg = d3.select("svg");
    var svgGroup = svg.append("g");

    // Run the renderer. This is what draws the final graph.
    render(d3.select("svg g"), g);

    // make the svg big enough
    $('svg').width(g.graph().width).height(g.graph().height);
}