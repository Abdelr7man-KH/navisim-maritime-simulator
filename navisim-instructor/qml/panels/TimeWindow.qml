import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root
    width: 450; height: 400
    modal: true; focus: true
    anchors.centerIn: Overlay.overlay

    readonly property color accentColor: "#00bfff"
    readonly property color textMuted: "#64748b"

    Overlay.modal: Rectangle { color: "#80000000" }
    background: Rectangle { color: "#f8fafc"; radius: 8 }

    ColumnLayout {
        anchors.fill: parent; anchors.margins: 25; spacing: 20

        Text {
            text: "Time & Celestial"
            font.pixelSize: 18; color: "#1e293b"; font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        // TIME OF DAY (Float 0 - 24)
        RowLayout {
            Text { text: "Time (Float)"; font.pixelSize: 12; color: root.textMuted; Layout.fillWidth: true }
            Text { text: timeSlider.value.toFixed(2); font.bold: true; color: root.accentColor }
        }
        Slider {
            id: timeSlider
            from: 0.0; to: 24.0; value: 12.0; stepSize: 0.1
            Layout.fillWidth: true
        }

        // ROTATION (Float 0 - 360)
        RowLayout {
            Text { text: "Celestial Rotation (Sun/Moon)"; font.pixelSize: 12; color: root.textMuted; Layout.fillWidth: true }
            Text { text: rotationSlider.value.toFixed(1) + "°"; font.bold: true; color: root.accentColor }
        }
        Slider {
            id: rotationSlider
            from: 0.0; to: 360.0; value: 0.0; stepSize: 0.5
            Layout.fillWidth: true
        }

        Item { Layout.fillHeight: true } // Spacer

        // APPLY BUTTON
        Rectangle {
            Layout.fillWidth: true; height: 45
            color: applyMouse.pressed ? "#1d4ed8" : "#2563eb"; radius: 4
            Text { text: "APPLY TIME"; color: "white"; font.bold: true; anchors.centerIn: parent }
            MouseArea {
                id: applyMouse; anchors.fill: parent
                onClicked: {
                    var payload = {
                            "time": Number(timeSlider.value),
                            "rotation": Number(rotationSlider.value)
                    };
                    console.log("Publishing Partial:", JSON.stringify(payload, null, 2));
                    physicsBridge.publishEnvironment("WEATHER",payload);
                    root.close();
                }
            }
        }
    }
}
