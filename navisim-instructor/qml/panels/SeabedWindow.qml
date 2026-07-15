// panels/SeabedWindow.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root
    width: 450; height: 490
    modal: true; focus: true
    anchors.centerIn: Overlay.overlay

    readonly property color accentColor: "#00bfff"
    readonly property color textMuted: "#64748b"

    Overlay.modal: Rectangle { color: "#80000000" }
    background: Rectangle { color: "#f8fafc"; radius: 8 }

    ColumnLayout {
        anchors.fill: parent; anchors.margins: 25; spacing: 20

        Text { text: "Seabed Conditions"; font.pixelSize: 18; color: "#1e293b"; font.bold: true; Layout.alignment: Qt.AlignHCenter }

        Text { text: "Seabed Type"; font.pixelSize: 12; color: root.textMuted }
        ComboBox {
            id: seabedCombo
            model: ["Sand", "Mud", "Rock", "Clay", "Gravel"]
            Layout.fillWidth: true
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: "#cbd5e1"; Layout.margins: 5 }

        // MUD THICKNESS
        RowLayout {
            Text { text: "Muddy Strata Thickness (m)"; font.pixelSize: 12; color: root.textMuted; Layout.fillWidth: true }
            Text { text: muddyThicknessSlider.value.toFixed(1); font.bold: true; color: root.accentColor }
        }
        Slider { id: muddyThicknessSlider; from: 0.0; to: 10.0; value: 0.0; stepSize: 0.1; Layout.fillWidth: true }

        // MUD DENSITY
        RowLayout {
            Text { text: "Muddy Strata Density (kg/m³)"; font.pixelSize: 12; color: root.textMuted; Layout.fillWidth: true }
            Text { text: muddyDensitySlider.value.toFixed(1); font.bold: true; color: root.accentColor }
        }
        Slider { id: muddyDensitySlider; from: 1000.0; to: 2000.0; value: 1200.0; stepSize: 1.0; Layout.fillWidth: true }

        Item { Layout.fillHeight: true }

        Rectangle {
            Layout.fillWidth: true; height: 45
            color: applyMouse.pressed ? "#1d4ed8" : "#2563eb"; radius: 4
            Text { text: "APPLY SEABED"; color: "white"; font.bold: true; anchors.centerIn: parent }
            MouseArea {
                id: applyMouse; anchors.fill: parent
                onClicked: {
                    var payload = {
                        "seabed": {
                            "type": seabedCombo.currentValue
                        },
                        "muddy_strata": {
                            "thickness_m": Number(muddyThicknessSlider.value),
                            "density_kg_m3": Number(muddyDensitySlider.value)
                        }
                    };
                    console.log("Publishing:", JSON.stringify(payload, null, 2));
                    EnvironmentController.publishEnvironment(payload);
                    root.close();
                }
            }
        }
    }
}
