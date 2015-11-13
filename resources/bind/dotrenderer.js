/** @opaType graph */
/** @opaType list('a) */
var graph;
var listener;
/**
 * @register {graph, (string -> void)-> void}
 */
function draw(cfg, click) {
    console.log(cfg);
    graph = new dagreD3.graphlib.Graph({multigraph: true}).setGraph({});

    map_iter(cfg, function (k, e) {
        iter(e, add_edges);
    });

    listener = click;
    render(graph, ".cfg");

    // undo zoom and translation... TODO this does not work yet
    // d3.behavior.zoom().x(1).y(1);
    // var svg = d3.select(".cfg");
    // var svgGroup = svg.select("g");
    // svgGroup.attr("transform", "none");
}

function add_edges(e) {
    var es = e.es;

    var a = e.a.f1;
    var b;
    var lbl = e.a.f2;
    graph.setNode(a, {});
    while (!es.hasOwnProperty('nil')) {
        // add new node & edge
        b = es.hd.f1;
        graph.setNode(b, {});
        graph.setEdge(a, b, {label: lbl}, Math.random().toString(36).substr(2, 5));
        a = b;
        lbl = es.hd.f2;
        es = es.tl;
    }

    b = e.e;
    graph.setNode(b, {});
    graph.setEdge(a, b, {label: lbl}, Math.random().toString(36).substr(2, 5));
}

/**
 * @register {list(string) -> void}
 */
function highlight(highlights) {
    console.log(highlights);
    unhighlight();
    iter(highlights, function (elem) {
        graph.setNode(elem, {style: "fill: green"});
    });
    render(graph, ".cfg");
}

function unhighlight() {
    graph.nodes().forEach(function (n) {
        graph.setNode(n, {style: "fill: white"})
    });
}

function render(g, target) {
    var render = new dagreD3.render();
    var svg = d3.select(target);
    var svgGroup = svg.select("g");

    render(svgGroup, graph);
    // $('svg').width(g.graph().width).height(g.graph().height);
    svg.call(d3.behavior.zoom().on('zoom', function () {
        var ev = d3.event;
        svgGroup.attr("transform", "translate(" + ev.translate + ") scale(" + ev.scale + ")");
    }));

    // create a listener
    svgGroup.selectAll("g.node")
        .on('click', listener);
}

function map_iter(map, f) {
    if (!map.hasOwnProperty('empty')) {
        f(map.key, map.value);
        map_iter(map.left, f);
        map_iter(map.right, f);
    }
}

/**
 * list('a) -> ('a -> void) -> void
 */
function iter(ls, f) {
    while (!ls.hasOwnProperty('nil')) {
        f(ls.hd);
        ls = ls.tl;
    }
}