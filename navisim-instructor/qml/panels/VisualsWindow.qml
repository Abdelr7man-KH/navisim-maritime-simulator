// panels/VisualsWindow.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root
    width: 350; height: 350
    modal: true; focus: true
    anchors.centerIn: Overlay.overlay

    readonly property color accentColor: "#00bfff"
    readonly property color textMuted: "#64748b"

    Overlay.modal: Rectangle { color: "#80000000" }
    background: Rectangle { color: "#f8fafc"; radius: 8 }

    ColumnLayout {
        anchors.fill: parent; anchors.margins: 25; spacing: 20

        Text { text: "Sea Visuals"; font.pixelSize: 18; color: "#1e293b"; font.bold: true; Layout.alignment: Qt.AlignHCenter }

        CheckBox { id: whitecapsCheck; text: "Render Whitecaps"; checked: true; font.pixelSize: 14 }
        CheckBox { id: foamCheck; text: "Render Sea Foam"; checked: true; font.pixelSize: 14 }
        CheckBox { id: dropsCheck; text: "Drops on Glass"; checked: false; font.pixelSize: 14 }

        Item { Layout.fillHeight: true }

        Rectangle {
            Layout.fillWidth: true; height: 45
            color: applyMouse.pressed ? "#1d4ed8" : "#2563eb"; radius: 4
            Text { text: "APPLY VISUALS"; color: "white"; font.bold: true; anchors.centerIn: parent }
            MouseArea {
                id: applyMouse; anchors.fill: parent
                onClicked: {
                    var payload = {
                        "sea_visuals": {
                            "whitecaps": whitecapsCheck.checked,
                            "foam": foamCheck.checked,
                            "drops_on_glass": dropsCheck.checked
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