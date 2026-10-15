.pragma library

// Password mask glyphs, drawn as closed polylines in a 24 x 24 box. They stay in Noctalia's order
// (circle, pentagon, star, rounded square, pick, blob, triangle) and are chosen by position in the
// password, so a keystroke never reshuffles the dots already typed. Points sit inside the box by half
// the 2.5 px round-joined stroke LockDot adds, which is what softens the corners.

var CENTER = 12;

function polygon(count, outer, inner, rotation) {
    var points = [];
    var steps = inner > 0 ? count * 2 : count;
    for (var i = 0; i < steps; i++) {
        var radius = inner > 0 && i % 2 === 1 ? inner : outer;
        var angle = rotation + i * 2 * Math.PI / steps;
        points.push(Qt.point(CENTER + radius * Math.cos(angle), CENTER + radius * Math.sin(angle)));
    }
    points.push(points[0]);
    return points;
}

function polar(steps, radiusAt) {
    var points = [];
    for (var i = 0; i < steps; i++) {
        var angle = i * 2 * Math.PI / steps;
        var radius = radiusAt(angle);
        points.push(Qt.point(CENTER + radius * Math.cos(angle), CENTER + radius * Math.sin(angle)));
    }
    points.push(points[0]);
    return points;
}

var UP = -Math.PI / 2;

var shapes = [
    polar(40, function (angle) { return 7.6; }),
    polygon(5, 8.2, 0, UP),
    polygon(8, 8.6, 5.6, UP),
    polar(48, function (angle) {
        // Superellipse: a square with soft corners.
        var c = Math.abs(Math.cos(angle)), s = Math.abs(Math.sin(angle));
        return 7.2 / Math.pow(Math.pow(c, 5) + Math.pow(s, 5), 1 / 5);
    }),
    // Guitar pick: a triangle pointing down, rounded harder than the plain one.
    [Qt.point(5.2, 6.2), Qt.point(18.8, 6.2), Qt.point(12, 18.2), Qt.point(5.2, 6.2)],
    polar(60, function (angle) { return 7.2 + 1.1 * Math.sin(3 * angle + 0.6) + 0.7 * Math.sin(2 * angle + 1.4); }),
    [Qt.point(12, 4.6), Qt.point(19.4, 17.4), Qt.point(4.6, 17.4), Qt.point(12, 4.6)]
];

var count = shapes.length;

function points(kind) {
    return shapes[((kind % count) + count) % count];
}
