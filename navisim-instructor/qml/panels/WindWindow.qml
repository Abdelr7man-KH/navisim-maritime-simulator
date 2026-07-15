// // panels/WindWindow.qml

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root
    width: 450; height: 350 // Reduced height since we removed the sliders
    modal: true; focus: true
    anchors.centerIn: Overlay.overlay
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    readonly property color accentColor: "#00bfff"
    readonly property color textColor: "#334155"
    readonly property color textMuted: "#64748b"
    readonly property color borderColor: "#cbd5e1"

    Overlay.modal: Rectangle { color: "#80000000" }
    background: Rectangle { color: "#f8fafc"; radius: 8 }

    ColumnLayout {
        anchors.fill: parent; anchors.margins: 25; spacing: 20

        Text {
            text: "Wind & Waves"
            font.pixelSize: 18; color: "#1e293b"; font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            text: "Select Sea Scenario"
            font.pixelSize: 14; color: root.textMuted
            Layout.topMargin: 10
        }

        // Dropdown containing your 8 scenarios
        ComboBox {
            id: scenarioCombo
            Layout.fillWidth: true
            font.pixelSize: 14
            model: [
                "Calm",
                "Light Breeze",
                "Gentle Breeze",
                "Moderate Breeze",
                "Strong Breeze",
                "Gale",
                "Strong Gale",
                "Violent Storm"
            ]

            // Basic styling for the combo box to match your UI
            background: Rectangle {
                implicitHeight: 40
                border.color: root.borderColor
                radius: 6
            }
        }

        Item { Layout.fillHeight: true }

        // Apply Button with animations integrated
        Button {
            id: updateBtn
            text: "APPLY WIND & WAVES"
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            Layout.topMargin: 10

            // Scale animation
            scale: down ? 0.98 : 1.0
            Behavior on scale { NumberAnimation { duration: 100 } }

            // Color animation
            background: Rectangle {
                color: updateBtn.down ? "#0090cc" : (updateBtn.hovered ? "#00a8ff" : root.accentColor)
                radius: 8
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            contentItem: Text {
                text: updateBtn.text
                color: "white"
                font.bold: true
                font.pixelSize: 14
                font.letterSpacing: 1.2
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                opacity: updateBtn.down ? 0.8 : 1.0
            }

            onClicked: {
                // currentIndex is 0-indexed (0 to 7). We add 1 to match your Python keys "1" to "8".
                let profileId = (scenarioCombo.currentIndex + 1).toString();
                var payload = {
                        "weather_id":profileId
                };
                console.log("Publishing:", JSON.stringify(payload, null, 2));
                physicsBridge.publishEnvironment("WATER",payload);
                root.close();
            }
        }
    }
}
