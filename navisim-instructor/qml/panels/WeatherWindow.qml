import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: root
    width: 450; height: 600
    modal: true; focus: true
    anchors.centerIn: Overlay.overlay
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    readonly property color accentColor: "#00bfff"
    readonly property color textColor: "#334155"
    readonly property color textMuted: "#64748b"

    Overlay.modal: Rectangle { color: "#80000000" }
    background: Rectangle { color: "#f8fafc"; radius: 8 }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 25
        spacing: 20

        Text {
            text: "Weather Conditions"
            font.pixelSize: 18; color: "#1e293b"; font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        // RAIN
        Text { text: "Rain Intensity"; font.pixelSize: 12; color: root.textMuted }
        ComboBox {
            id: rainCombo
            model: ["Off", "Low", "Medium", "High"]
            Layout.fillWidth: true
        }

        // STORM
        RowLayout {
            Text { text: "Storm Level"; font.pixelSize: 12; color: root.textMuted; Layout.fillWidth: true }
            Text { text: stormSlider.value.toFixed(2); font.bold: true; color: root.accentColor }
        }
        Slider {
            id: stormSlider
            from: 0.0; to: 1.0; value: 0.0; stepSize: 0.05
            Layout.fillWidth: true
        }
        Text {
            text: stormSlider.value >= 0.7 ? "Status: Storm ON" : "Status: Normal"
            font.pixelSize: 11; color: root.textMuted
        }

        // THUNDERSTORM
        CheckBox {
            id: tStormCheck
            text: "Enable Thunderstorm"
        }

        Item { Layout.fillHeight: true } // Spacer

        // APPLY BUTTON
        Rectangle {
            Layout.fillWidth: true; height: 45
            color: applyMouse.pressed ? "#1d4ed8" : "#2563eb"; radius: 4
            Text { text: "APPLY WEATHER"; color: "white"; font.bold: true; anchors.centerIn: parent }
            MouseArea {
                id: applyMouse; anchors.fill: parent
                onClicked: {
                    // Helper to convert Rain string to Float
                    let rainVal = 0.0;
                    if (rainCombo.currentValue === "Low") rainVal = 3000.0;
                    else if (rainCombo.currentValue === "Medium") rainVal = 6000.0;
                    else if (rainCombo.currentValue === "High") rainVal = 10000.0;

                    // Thunderstorm: Off = 10.0, On = 0.0
                    let thunderVal = tStormCheck.checked ? 0.0 : 10.0;

                    var payload = {
                            "rain": rainVal,
                            "storm": Number(stormSlider.value), // Ensuring float
                            "lightning": thunderVal
                    };
                    physicsBridge.publishEnvironment("WEATHER",payload);
                    root.close();
                }
            }
        }
    }
}
// // panels/WeatherWindow.qml
// import QtQuick
// import QtQuick.Controls
// import QtQuick.Layouts

// Popup {
//     id: root
//     width: 450
//     height: 700
//     modal: true
//     focus: true
//     anchors.centerIn: Overlay.overlay
//     closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

//     // Aliases to allow EnvironmentPanel to read the values for the JSON payload
//     property alias weatherCombo: weatherCombo
//     property alias precipCombo: precipCombo
//     property alias visibilitySlider: visibilitySlider

//     // Color Palette
//     readonly property color accentColor: "#00bfff"
//     readonly property color textColor: "#334155"
//     readonly property color textMuted: "#64748b"
//     readonly property color borderColor: "#cbd5e1"
    
//     // Dim the background
//     Overlay.modal: Rectangle { color: "#80000000" }

//     background: Rectangle {
//         color: "#f8fafc"
//         radius: 8
//     }

//     // --- REUSABLE MODERN COMBOBOX (Local Scope) ---
//     component ModernComboBox: ComboBox {
//         id: control
//         font.pixelSize: 13
//         delegate: ItemDelegate {
//             width: control.width
//             contentItem: Text {
//                 text: modelData
//                 color: control.highlightedIndex === index ? "white" : root.textColor
//                 font: control.font
//                 elide: Text.ElideRight
//                 verticalAlignment: Text.AlignVCenter
//             }
//             background: Rectangle {
//                 radius: 4
//                 color: control.highlightedIndex === index ? root.accentColor : "transparent"
//                 anchors.margins: 4
//             }
//             highlighted: control.highlightedIndex === index
//         }
//         contentItem: Text {
//             leftPadding: 12
//             rightPadding: control.indicator.width + control.spacing
//             text: control.displayText
//             font: control.font
//             color: root.textColor
//             verticalAlignment: Text.AlignVCenter
//             elide: Text.ElideRight
//         }
//         background: Rectangle {
//             implicitWidth: 140
//             implicitHeight: 38
//             border.color: control.pressed ? root.accentColor : root.borderColor
//             border.width: control.pressed ? 2 : 1
//             radius: 6
//             color: "white"
//         }
//         popup: Popup {
//             y: control.height - 1
//             width: control.width
//             implicitHeight: contentItem.implicitHeight
//             padding: 4
//             contentItem: ListView {
//                 clip: true
//                 implicitHeight: contentHeight
//                 model: control.popup.visible ? control.delegateModel : null
//                 currentIndex: control.highlightedIndex
//             }
//             background: Rectangle {
//                 color: "white"
//                 border.color: root.borderColor
//                 radius: 8
//                 Rectangle { z: -1; anchors.fill: parent; anchors.margins: -2; anchors.topMargin: 2; color: "#1A000000"; radius: 8 }
//             }
//         }
//     }

//     // --- REUSABLE MODERN SLIDER (Local Scope) ---
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

//     ColumnLayout {
//         anchors.fill: parent
//         anchors.margins: 30
//         spacing: 20

//         // Header Title
//         ColumnLayout {
//             Layout.alignment: Qt.AlignHCenter
//             spacing: 5
//             Text {
//                 text: "Weather Conditions"
//                 font.pixelSize: 18
//                 color: "#1e293b"
//                 Layout.alignment: Qt.AlignHCenter
//             }
//             Text {
//                 text: "Configure precipitation, visibility, and weather force."
//                 font.pixelSize: 14
//                 color: "#64748b"
//                 Layout.alignment: Qt.AlignHCenter
//             }
//         }

//         // Main Card
//         Rectangle {
//             Layout.fillWidth: true
//             Layout.fillHeight: true
//             color: "#ffffff"
//             radius: 8
//             border.color: "#e2e8f0"

//             ColumnLayout {
//                 anchors.fill: parent
//                 anchors.margins: 25
//                 spacing: 15

//                 // Image Placeholder
//                 Rectangle {
//                     Layout.fillWidth: true
//                     Layout.preferredHeight: 180
//                     color: "#cbd5e1"
//                     radius: 4
//                     clip: true
//                     Text {
//                         anchors.centerIn: parent
//                         text: "Weather Image\n(Add your source here)"
//                         horizontalAlignment: Text.AlignHCenter
//                         color: "#64748b"
//                     }
//                 }

//                 // Controls
//                 ColumnLayout {
//                     Layout.fillWidth: true
//                     spacing: 14

//                     Text { text: "Weather Type"; font.pixelSize: 12; color: root.textMuted }
//                     ModernComboBox {
//                         id: weatherCombo
//                         Layout.fillWidth: true
//                         model: [
//                             "Calm (Force 0)", "Very Light (Force 1)", "Light Breeze (Force 2)",
//                             "Gentle Breeze (Force 3)", "Moderate Breeze (Force 4)", "Fresh Breeze (Force 5)",
//                             "Strong Breeze (Force 6)", "Near Gale (Force 7)", "Gale (Force 8)",
//                             "Strong Gale (Force 9)", "Storm (Force 10)", "Violent Storm (Force 11)"
//                         ]
//                     }

//                     Text { text: "Precipitation"; font.pixelSize: 12; color: root.textMuted }
//                     ModernComboBox { id: precipCombo; model: ["None", "Rain", "Snow"]; Layout.fillWidth: true }

//                     RowLayout {
//                         Layout.fillWidth: true
//                         Text { text: "Visibility"; font.pixelSize: 12; color: root.textMuted; Layout.fillWidth: true }
//                         Text { text: visibilitySlider.value.toFixed(1) + " nm"; font.pixelSize: 13; font.bold: true; color: root.accentColor }
//                     }
//                     ModernSlider { id: visibilitySlider; from: 0.1; to: 20.0; value: 10.0; Layout.fillWidth: true }
//                 }
//             }
//         }

//         // Bottom Action
//         RowLayout {
//             Layout.fillWidth: true
//             Layout.alignment: Qt.AlignRight
//             Rectangle {
//                 width: 140; height: 45
//                 color: btnMouse.pressed ? "#1d4ed8" : "#2563eb"
//                 radius: 4
//                 Text { text: "APPLY"; color: "white"; font.bold: true; anchors.centerIn: parent }
//                 MouseArea {
//                     id: btnMouse
//                     anchors.fill: parent
//                     cursorShape: Qt.PointingHandCursor
//                     onClicked: root.close()
//                 }
//             }
//         }
//     }
// }
