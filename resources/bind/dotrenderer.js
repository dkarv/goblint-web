/** @opaType Model.graph */
/**
 * @opaType list('a)
 */
/**
 * @register {string -> void}
 * Deprecated
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
    // console.log(g.graph().width);
    // $('svg').width(g.graph().width).height(g.graph().height);
    var initialScale = 0.75;
    zoom.translate()
}
/**
 * @register {Model.graph, (string -> void)-> void}
 */
function draw(cfg, click) {
    console.log("tests", cfg);
    var g = new dagreD3.graphlib.Graph().setGraph({});
    call(cfg.vertices, function (elem) {
        g.setNode(elem.id, {label: elem.label});
    });
    call(cfg.edges, function (edge) {
        console.log(edge);
        g.setEdge(edge.start, edge.end, {label: edge.label});
    });
    var render = new dagreD3.render();
    var svg = d3.select("svg");
    var svgGroup = svg.append("g");

    render(svgGroup, g);
    // $('svg').width(g.graph().width).height(g.graph().height);
    svg.call(d3.behavior.zoom().on('zoom', function () {
        var ev = d3.event;
        svgGroup.attr("transform", "translate(" + ev.translate + ") scale(" + ev.scale + ")");
    }));

    // create a listener
    svgGroup.selectAll("g.node")
        .on('click', click);
}
/**
 * list('a) -> ('a -> void) -> void
 */
function call(ls, f) {
    while (!ls.hasOwnProperty('nil')) {
        f(ls.hd);
        ls = ls.tl;
    }
}