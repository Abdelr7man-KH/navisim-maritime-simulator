// panels/CurrentWindow.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root
    width: 450; height: 590
    modal: true; focus: true
    anchors.centerIn: Overlay.overlay

    readonly property color accentColor: "#00bfff"
    readonly property color textMuted: "#64748b"

    Overlay.modal: Rectangle { color: "#80000000" }
    background: Rectangle { color: "#f8fafc"; radius: 8 }

    ColumnLayout {
        anchors.fill: parent; anchors.margins: 25; spacing: 20

        Text { text: "Currents & Tides"; font.pixelSize: 18; color: "#1e293b"; font.bold: true; Layout.alignment: Qt.AlignHCenter }

        // CURRENT SPEED
        RowLayout {
            Text { text: "Current Speed (kn)"; font.pixelSize: 12; color: root.textMuted; Layout.fillWidth: true }
            Text { text: currentSpeedSlider.value.toFixed(1); font.bold: true; color: root.accentColor }
        }
        Slider { id: currentSpeedSlider; from: 0.0; to: 10.0; value: 1.2; stepSize: 0.1; Layout.fillWidth: true }

        // CURRENT DIRECTION
        RowLayout {
            Text { text: "Current Direction (°)"; font.pixelSize: 12; color: root.textMuted; Layout.fillWidth: true }
            Text { text: currentDirSlider.value.toFixed(1); font.bold: true; color: root.accentColor }
        }
        Slider { id: currentDirSlider; from: 0.0; to: 359.0; value: 180.0; stepSize: 1.0; Layout.fillWidth: true }

        Rectangle { Layout.fillWidth: true; height: 1; color: "#cbd5e1"; Layout.margins: 5 }

        // TIDE HEIGHT
        RowLayout {
            Text { text: "Tide Height (m)"; font.pixelSize: 12; color: root.textMuted; Layout.fillWidth: true }
            Text { text: tideSlider.value.toFixed(1); font.bold: true; color: root.accentColor }
        }
        Slider { id: tideSlider; from: -5.0; to: 15.0; value: 2.5; stepSize: 0.1; Layout.fillWidth: true }

        // SONIC SPEED
        RowLayout {
            Text { text: "Sonic Speed (m/s)"; font.pixelSize: 12; color: root.textMuted; Layout.fillWidth: true }
            Text { text: sonicSpeedSlider.value.toFixed(1); font.bold: true; color: root.accentColor }
        }
        Slider { id: sonicSpeedSlider; from: 1400.0; to: 1600.0; value: 1500.0; stepSize: 0.5; Layout.fillWidth: true }

        Item { Layout.fillHeight: true }

        Rectangle {
            Layout.fillWidth: true; height: 45
            color: applyMouse.pressed ? "#1d4ed8" : "#2563eb"; radius: 4
            Text { text: "APPLY CURRENTS"; color: "white"; font.bold: true; anchors.centerIn: parent }
            MouseArea {
                id: applyMouse; anchors.fill: parent
                onClicked: {
                    var payload = {
                        "current": {
                            "speed": Number(currentSpeedSlider.value),
                            "direction": Number(currentDirSlider.value)
                        },
                        "tide": { "height": Number(tideSlider.value) },
                        "sonic": { "speed": Number(sonicSpeedSlider.value) }
                    };
                    console.log("Publishing:", JSON.stringify(payload, null, 2));
                    EnvironmentController.publishEnvironment(payload);
                    root.close();
                }
            }
        }
    }
}
