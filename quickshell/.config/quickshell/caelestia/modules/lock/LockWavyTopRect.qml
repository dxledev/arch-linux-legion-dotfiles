import QtQuick
import QtQuick.Shapes
import qs.components
import qs.services

Shape {
    id: root

    property color color: Colours.palette.m3surfaceContainer
    property int waves: 4
    property real amplitude: 3
    readonly property real waveHeight: amplitude * 2

    preferredRendererType: Shape.CurveRenderer
    asynchronous: true

    ShapePath {
        strokeWidth: 0
        strokeColor: "transparent"
        fillColor: root.color

        PathSvg {
            path: {
                const width = root.width;
                const height = root.height;
                const amplitude = root.amplitude;
                const waveLength = width / Math.max(1, root.waves);
                const halfWave = waveLength / 2;
                let path = `M 0,${amplitude} `;
                for (let index = 0; index < root.waves; ++index) {
                    const x = index * waveLength;
                    path += `Q ${x + halfWave / 2},${-amplitude} ${x + halfWave},${amplitude} `;
                    path += `Q ${x + halfWave + halfWave / 2},${3 * amplitude} ${x + waveLength},${amplitude} `;
                }
                return `${path}L ${width},${height} L 0,${height} Z`;
            }
        }

        Behavior on fillColor {
            CAnim {}
        }
    }
}
