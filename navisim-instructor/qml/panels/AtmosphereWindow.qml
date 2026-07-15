// panels/AtmosphereWindow.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root
    width: 450; height: 500
    modal: true; focus: true
    anchors.centerIn: Overlay.overlay

    readonly property color accentColor: "#00bfff"
    readonly property color textMuted: "#64748b"

    Overlay.modal: Rectangle { color: "#80000000" }
    background: Rectangle { color: "#f8fafc"; radius: 8 }

    ColumnLayout {
        anchors.fill: parent; anchors.margins: 25; spacing: 20

        Text {
            text: "Atmosphere & Fog"
            font.pixelSize: 18; color: "#1e293b"; font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        // FOG DENSITY
        RowLayout {
            Text { text: "Fog Density"; font.pixelSize: 12; color: root.textMuted; Layout.fillWidth: true }
            Text { text: fogDensitySlider.value.toFixed(2); font.bold: true; color: root.accentColor }
        }
        Slider {
            id: fogDensitySlider
            from: 0.0; to: 1.0; value: 0.0; stepSize: 0.05
            Layout.fillWidth: true
        }
        Text {
            text: {
                if (fogDensitySlider.value >= 0.8) return "Very High";
                if (fogDensitySlider.value >= 0.4) return "Medium";
                return "Low";
            }
            font.pixelSize: 11; color: root.textMuted
        }

        Item { Layout.fillHeight: true } // Spacer

        // APPLY BUTTON
        Rectangle {
            Layout.fillWidth: true; height: 45
            color: applyMouse.pressed ? "#1d4ed8" : "#2563eb"; radius: 4
            Text { text: "APPLY ATMOSPHERE"; color: "white"; font.bold: true; anchors.centerIn: parent }
            MouseArea {
                id: applyMouse; anchors.fill: parent
                onClicked: {
                    var payload = {
                            "fog_density": Number(fogDensitySlider.value)
                    };
                    console.log("Publishing Partial:", JSON.stringify(payload, null, 2));
                    physicsBridge.publishEnvironment("WEATHER",payload);
                    root.close();
                }
            }
        }
    }
}
// import QtQuick
// import QtQuick.Controls
// import QtQuick.Layouts

// Popup {
//     id: root
//     width: 450
//     height: 700 // Set to a sensible max height, ScrollView handles the rest!
//     modal: true
//     focus: true
//     anchors.centerIn: Overlay.overlay
//     closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

//     // Aliases to allow EnvironmentPanel to read the values
//     property alias humiditySlider: humiditySlider
//     property alias atmosphereTempSlider: atmosphereTempSlider
//     property alias pressureSlider: pressureSlider
//     property alias fogHeightSlider: fogHeightSlider
//     property alias fogVisibilitySlider: fogVisibilitySlider
//     property alias fogTimeCheck: fogTimeCheck

//     // Color Palette
//     readonly property color accentColor: "#00bfff"
//     readonly property color textColor: "#334155"
//     readonly property color textMuted: "#64748b"
//     readonly property color borderColor: "#cbd5e1"

//     Overlay.modal: Rectangle { color: "#80000000" }

//     background: Rectangle {
//         color: "#f8fafc"
//         radius: 8
//     }

//     // --- REUSABLE COMPONENTS ---
//     component ModernSlider: Slider {
//         id: mSlider
//         background: Rectangle {
//             x: mSlider.leftPadding
//             y: mSlider.topPadding + mSlider.availableHeight / 2 - height / 2
//             implicitWidth: 200; implicitHeight: 6
//             width: mSlider.availableWidth; height: implicitHeight
//             radius: 3; color: "#e2e8f0"
//             Rectangle {
//                 width: mSlider.visualPosition * parent.width
//                 height: parent.height; color: root.accentColor; radius: 3
//             }
//         }
//         handle: Rectangle {
//             x: mSlider.leftPadding + mSlider.visualPosition * (mSlider.availableWidth - width)
//             y: mSlider.topPadding + mSlider.availableHeight / 2 - height / 2
//             implicitWidth: 24; implicitHeight: 24
//             radius: 12; color: "white"
//             border.color: root.accentColor; border.width: 5
//         }
//     }

//     component ModernCheckBox: CheckBox {
//         id: mCheck
//         font.pixelSize: 13
//         indicator: Rectangle {
//             implicitWidth: 20; implicitHeight: 20
//             x: mCheck.leftPadding; y: parent.height / 2 - height / 2
//             radius: 4; border.color: root.borderColor; border.width: 1.5; color: "white"
//             Text {
//                 anchors.centerIn: parent; text: "✔"; color: root.accentColor
//                 font.pixelSize: 14; font.bold: true; visible: mCheck.checked
//             }
//         }
//         contentItem: Text {
//             text: mCheck.text; font: mCheck.font; color: root.textColor
//             verticalAlignment: Text.AlignVCenter
//             leftPadding: mCheck.indicator.width + mCheck.spacing + 6
//         }
//     }

//     ColumnLayout {
//         anchors.fill: parent
//         anchors.margins: 30
//         spacing: 20

//         // --- 1. FIXED HEADER ---
//         ColumnLayout {
//             Layout.alignment: Qt.AlignHCenter
//             spacing: 5
//             Text {
//                 text: "Atmosphere & Fog"
//                 font.pixelSize: 18; color: "#1e293b"; Layout.alignment: Qt.AlignHCenter
//             }
//             Text {
//                 text: "Configure temperature, pressure, and fog intensity."
//                 font.pixelSize: 14; color: "#64748b"; Layout.alignment: Qt.AlignHCenter
//             }
//         }

//         // --- 2. SCROLLABLE CONTENT CARD ---
//         Rectangle {
//             Layout.fillWidth: true
//             Layout.fillHeight: true
//             color: "#ffffff"
//             radius: 8
//             border.color: "#e2e8f0"
//             clip: true // Prevents scroll content from overlapping the rounded corners!

//             ScrollView {
//                 anchors.fill: parent
//                 contentWidth: availableWidth
//                 clip: true
//                 ScrollBar.vertical.policy: ScrollBar.AsNeeded
//                 ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

//                 // Wrapper Item to maintain the 25px padding inside the ScrollView
//                 Item {
//                     width: parent.width
//                     implicitHeight: contentLayout.implicitHeight + 50 // Adds 25px top and bottom margin

//                     ColumnLayout {
//                         id: contentLayout
//                         anchors.top: parent.top
//                         anchors.left: parent.left
//                         anchors.right: parent.right
//                         anchors.margins: 25
//                         spacing: 15

//                         // Image Placeholder
//                         Rectangle {
//                             Layout.fillWidth: true; Layout.preferredHeight: 180
//                             color: "#cbd5e1"; radius: 4; clip: true
//                             Text {
//                                 anchors.centerIn: parent; text: "Atmosphere Image\n(Add your source here)"
//                                 horizontalAlignment: Text.AlignHCenter; color: "#64748b"
//                             }
//                         }

//                         // Controls
//                         ColumnLayout {
//                             Layout.fillWidth: true; spacing: 14

//                             RowLayout {
//                                 Text { text: "Humidity (%)"; Layout.fillWidth: true; font.pixelSize: 12; color: root.textMuted }
//                                 Text { text: humiditySlider.value.toFixed(0); font.bold: true; color: root.accentColor }
//                             }
//                             ModernSlider { id: humiditySlider; from: 0; to: 100; value: 70; Layout.fillWidth: true }

//                             RowLayout {
//                                 Text { text: "Temp (°C)"; Layout.fillWidth: true; font.pixelSize: 12; color: root.textMuted }
//                                 Text { text: atmosphereTempSlider.value.toFixed(1); font.bold: true; color: root.accentColor }
//                             }
//                             ModernSlider { id: atmosphereTempSlider; from: -50; to: 50; value: 15; Layout.fillWidth: true }

//                             RowLayout {
//                                 Text { text: "Pressure (hPa)"; Layout.fillWidth: true; font.pixelSize: 12; color: root.textMuted }
//                                 Text { text: pressureSlider.value.toFixed(0); font.bold: true; color: root.accentColor }
//                             }
//                             ModernSlider { id: pressureSlider; from: 900; to: 1100; value: 1013; Layout.fillWidth: true }

//                             Rectangle { Layout.fillWidth: true; height: 1; color: root.borderColor; Layout.margins: 5 }

//                             RowLayout {
//                                 Text { text: "Fog Height (m)"; Layout.fillWidth: true; font.pixelSize: 12; color: root.textMuted }
//                                 Text { text: fogHeightSlider.value.toFixed(0); font.bold: true; color: root.accentColor }
//                             }
//                             ModernSlider { id: fogHeightSlider; from: 0; to: 500; value: 50; Layout.fillWidth: true }

//                             RowLayout {
//                                 Text { text: "Fog Visibility (nm)"; Layout.fillWidth: true; font.pixelSize: 12; color: root.textMuted }
//                                 Text { text: fogVisibilitySlider.value.toFixed(1); font.bold: true; color: root.accentColor }
//                             }
//                             ModernSlider { id: fogVisibilitySlider; from: 0; to: 10; value: 2.0; Layout.fillWidth: true }

//                             ModernCheckBox { id: fogTimeCheck; text: "Use Absolute Time for Fog Changes" }
//                         }
//                     }
//                 }
//             }
//         }

//         // --- 3. FIXED BOTTOM ACTION ---
//         RowLayout {
//             Layout.fillWidth: true; Layout.alignment: Qt.AlignRight
//             Rectangle {
//                 width: 140; height: 45; color: btnMouse.pressed ? "#1d4ed8" : "#2563eb"; radius: 4
//                 Text { text: "APPLY"; color: "white"; font.bold: true; anchors.centerIn: parent }
//                 MouseArea { id: btnMouse; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.close() }
//             }
//         }
//     }
// }
