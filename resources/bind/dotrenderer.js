/** @opaType Model.graph */
var g;
var listener;
/**
 * @register {Model.graph, (string -> void)-> void}
 */
function draw(cfg, click) {
    g = new dagreD3.graphlib.Graph().setGraph({});
    call(cfg.vertices, function (elem) {
        g.setNode(elem.id, {label: elem.label});
    });
    call(cfg.edges, function (edge) {
        g.setEdge(edge.start, edge.end, {label: edge.label});
    });

    listener = click;
    render();

    // console.log(g);
    // setTimeout(testing, 8000);
}

/**
 * @register { -> void}
 */
function testing() {
    g.setNode("testing", {label: "blabla"});
    g.setEdge("1", "testing", {label: "edge"});
    render();
}

/**
 * @register {string -> void}
 */
function search(str) {
    // console.log(g.nodes());
    // console.log(g.labels());

    var pattern = new RegExp(str);
    g.nodes().forEach(function (n) {
        g.setNode(n, { style: "fill: white"})
    });
    g.edges().forEach(function (e) {
        edge = g.edge(e);
        //console.log(edge);
        if (edge.label.match(pattern)) {
            console.log("match!", e.v, e.w);
            g.setNode(e.v, {style: "fill: green"});
            g.setNode(e.w, {style: "fill: green"});
        }
    });
    render();
}

function render() {
    var render = new dagreD3.render();
    var svg = d3.select("svg");
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