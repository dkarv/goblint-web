/** @opaType Model.graph */
/** @opaType list('a) */
var g;
var listener;
/**
 * @register {Model.graph, (string -> void)-> void}
 */
function draw(cfg, click) {
    console.log(cfg);
    g = new dagreD3.graphlib.Graph().setGraph({});
    call(cfg.vertices, function (elem) {
        g.setNode(elem.id, {label: elem.label});
    });
    call(cfg.edges, function (edge) {
        g.setEdge(edge.start, edge.end, {label: edge.label});
    });

    listener = click;
    render(g, ".cfg");
}

/**
 * @register {list(string) -> void}
 */
function highlight(highlights) {
    console.log(highlights);
    unhighlight();
    call(highlights, function (elem) {
        g.setNode(elem, {style: "fill: green"});
    });
    render(g, ".cfg");
}

function unhighlight() {
    g.nodes().forEach(function (n) {
        g.setNode(n, {style: "fill: white"})
    });
}

function render(g, target) {
    var render = new dagreD3.render();
    var svg = d3.select(target);
    var svgGroup = svg.select("g");

    render(svgGroup, g);
    // $('svg').width(g.graph().width).height(g.graph().height);
    svg.call(d3.behavior.zoom().on('zoom', function () {
        var ev = d3.event;
        svgGroup.attr("transform", "translate(" + ev.translate + ") scale(" + ev.scale + ")");
    }));

    // create a listener
    svgGroup.selectAll("g.node")
        .on('click', listener);
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