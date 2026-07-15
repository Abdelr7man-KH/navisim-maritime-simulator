// panels/EnvironmentPanel.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"
import Esri.display_s57_chart 1.0
ColumnLayout {
    id: envRoot
    spacing: 16
    width: parent.width

    // --- COLOR PALETTE ---
    readonly property color accentColor: "#00bfff"
    readonly property color accentLight: "#e0f7fa"
    readonly property color textColor: "#334155"
    readonly property color textMuted: "#64748b"
    readonly property color borderColor: "#cbd5e1"
    readonly property color cardBg: "#ffffff"

    // --- INSTANTIATE ALL MODULAR WINDOWS ---
    TimeWindow { id: timeWin }
    WeatherWindow { id: weatherWin }
    AtmosphereWindow { id: atmosphereWin }
    WindWindow { id: windWin }

    // --- REUSABLE MENU BUTTON ---
    component MenuButton: Button {
        id: btn
        Layout.fillWidth: true
        Layout.preferredHeight: 52
        background: Rectangle {
            color: btn.down ? envRoot.accentLight : envRoot.cardBg
            border.color: btn.hovered ? envRoot.accentColor : envRoot.borderColor
            border.width: btn.hovered ? 2 : 1
            radius: 8
            Behavior on border.color { ColorAnimation { duration: 150 } }
        }
        contentItem: Text {
            text: btn.text
            color: envRoot.textColor
            font.bold: true
            font.pixelSize: 14
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    // --- MENU INTERFACE ---
    MenuButton { text: "⏱ Configure Time & Celestial"; onClicked: timeWin.open() }
    MenuButton { text: "⛈ Configure Weather Conditions"; onClicked: weatherWin.open() }
    MenuButton { text: "🌫 Configure Atmosphere & Fog"; onClicked: atmosphereWin.open() }
    MenuButton { text: "🌊 Configure Wind & Waves"; onClicked: windWin.open() }
}
// import QtQuick
// import QtQuick.Controls
// import QtQuick.Layouts
// import "../components"
// import Esri.display_s57_chart 1.0

// ColumnLayout {
//     id: envRoot
//     spacing: 24
//     width: parent.width

//     // --- COLOR PALETTE ---
//     readonly property color accentColor: "#00bfff" // Light blue from your images
//     readonly property color accentLight: "#e0f7fa"
//     readonly property color textColor: "#334155"
//     readonly property color textMuted: "#64748b"
//     readonly property color borderColor: "#cbd5e1"
//     readonly property color cardBg: "#ffffff"

//     // --- INSTANTIATE THE NEW WINDOWS ---
//     WeatherWindow { id: weatherWin }
//     AtmosphereWindow { id: atmosphereWin }

//     // --- COMPLETE JSON PUBLISHER ---
//     function applyAll() {
//         var payload = {
//             "datetime": {
//                 "date": dateInput.text,
//                 "time": timeInput.text,
//                 "season": seasonCombo.currentValue
//             },
//             "weather": {
//                 // Fetch values from the new Weather Window
//                 "type": weatherWin.weatherCombo.currentValue,
//                 "precipitation": weatherWin.precipCombo.currentValue,
//                 "visibility_nm": weatherWin.visibilitySlider.value
//             },
//             "wind_wave": {
//                 "wind_speed_knt": windSpeedSlider.value,
//                 "wind_dir_deg": windDirSpin.value,
//                 "wave_height_m": waveHeightSlider.value,
//                 "wave_dir_deg": sameDirCheck.checked ? windDirSpin.value : waveDirSpin.value
//             },
//             "current": {
//                 "speed": currentSpeedSlider.value,
//                 "direction": currentDirSpin.value
//             },
//             "tide": { "height": tideSlider.value },
//             "sonic": { "speed": sonicSpeedSlider.value },
//             "sea_visuals": {
//                 "whitecaps": whitecapsCheck.checked,
//                 "foam": foamCheck.checked,
//                 "drops_on_glass": dropsCheck.checked
//             },
//             "atmosphere": {
//                 // Fetch values from the new Atmosphere Window
//                 "temp_c": atmosphereWin.atmosphereTempSlider.value,
//                 "pressure_hpa": atmosphereWin.pressureSlider.value,
//                 "humidity_pct": atmosphereWin.humiditySlider.value
//             },
//             "fog": {
//                 // Fetch values from the new Atmosphere Window
//                 "height_m": atmosphereWin.fogHeightSlider.value,
//                 "visibility_range_nm": atmosphereWin.fogVisibilitySlider.value,
//                 "use_absolute_time": atmosphereWin.fogTimeCheck.checked
//             },
//             "muddy_strata": {
//                 "thickness_m": muddyThicknessSlider.value,
//                 "density_kg_m3": muddyDensitySlider.value
//             },
//             "seabed": {
//                 "type": seabedCombo.currentValue
//             }
//         };

//         console.log("Publishing Full Environment:\n", JSON.stringify(payload, null, 2));
//         EnvironmentController.publishEnvironment(payload);
//     }

//     // --- REUSABLE MODERN COMBOBOX COMPONENT ---
//     component ModernComboBox: ComboBox {
//         id: control
//         font.pixelSize: 13

//         delegate: ItemDelegate {
//             width: control.width
//             contentItem: Text {
//                 text: modelData
//                 color: control.highlightedIndex === index ? "white" : envRoot.textColor
//                 font: control.font
//                 elide: Text.ElideRight
//                 verticalAlignment: Text.AlignVCenter
//             }
//             background: Rectangle {
//                 radius: 4
//                 color: control.highlightedIndex === index ? envRoot.accentColor : "transparent"
//                 anchors.margins: 4
//             }
//             highlighted: control.highlightedIndex === index
//         }

//         contentItem: Text {
//             leftPadding: 12
//             rightPadding: control.indicator.width + control.spacing
//             text: control.displayText
//             font: control.font
//             color: envRoot.textColor
//             verticalAlignment: Text.AlignVCenter
//             elide: Text.ElideRight
//         }

//         background: Rectangle {
//             implicitWidth: 140
//             implicitHeight: 38
//             border.color: control.pressed ? envRoot.accentColor : envRoot.borderColor
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
//                 border.color: envRoot.borderColor
//                 radius: 8
//                 Rectangle {
//                     z: -1; anchors.fill: parent; anchors.margins: -2; anchors.topMargin: 2
//                     color: "#1A000000"; radius: 8
//                 }
//             }
//         }
//     }

//     // --- REUSABLE MODERN SLIDER COMPONENT ---
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
//                 height: parent.height; color: envRoot.accentColor; radius: 3
//             }
//         }
//         handle: Rectangle {
//             x: mSlider.leftPadding + mSlider.visualPosition * (mSlider.availableWidth - width)
//             y: mSlider.topPadding + mSlider.availableHeight / 2 - height / 2
//             implicitWidth: 24; implicitHeight: 24
//             radius: 12; color: "white"
//             border.color: envRoot.accentColor; border.width: 5
//         }
//     }

//     // --- REUSABLE MODERN CHECKBOX COMPONENT ---
//     component ModernCheckBox: CheckBox {
//         id: mCheck
//         font.pixelSize: 13
//         indicator: Rectangle {
//             implicitWidth: 20; implicitHeight: 20
//             x: mCheck.leftPadding; y: parent.height / 2 - height / 2
//             radius: 4; border.color: envRoot.borderColor; border.width: 1.5; color: "white"
//             Text {
//                 anchors.centerIn: parent
//                 text: "✔"
//                 color: envRoot.accentColor
//                 font.pixelSize: 14; font.bold: true
//                 visible: mCheck.checked
//             }
//         }
//         contentItem: Text {
//             text: mCheck.text; font: mCheck.font; color: envRoot.textColor
//             verticalAlignment: Text.AlignVCenter
//             leftPadding: mCheck.indicator.width + mCheck.spacing + 6
//         }
//     }

//     // --- 1. TIME & SEASON ---
//     GroupBox {
//         title: "Time & Season"
//         Layout.fillWidth: true
//         font.pixelSize: 14; font.bold: true
//         background: Rectangle { color: envRoot.cardBg; border.color: envRoot.borderColor; radius: 8 }

//         GridLayout {
//             columns: 2; anchors.fill: parent; rowSpacing: 16; columnSpacing: 12
//             Text { text: "Date:"; font.pixelSize: 12; color: envRoot.textMuted }
//             TextField {
//                 id: dateInput; text: "12.04.2026"; Layout.fillWidth: true
//                 background: Rectangle { border.color: envRoot.borderColor; radius: 6; implicitHeight: 38 }
//                 leftPadding: 12; color: envRoot.textColor
//             }

//             Text { text: "Time:"; font.pixelSize: 12; color: envRoot.textMuted }
//             TextField {
//                 id: timeInput; text: "14:20"; Layout.fillWidth: true
//                 background: Rectangle { border.color: envRoot.borderColor; radius: 6; implicitHeight: 38 }
//                 leftPadding: 12; color: envRoot.textColor
//             }

//             Text { text: "Season:"; font.pixelSize: 12; color: envRoot.textMuted }
//             ModernComboBox { id: seasonCombo; model: ["Summer", "Autumn", "Winter", "Spring"]; Layout.fillWidth: true }
//         }
//     }

//     // --- 2. WEATHER & VISIBILITY BUTTON ---
//     Button {
//         Layout.fillWidth: true
//         Layout.preferredHeight: 50
//         background: Rectangle {
//             color: parent.down ? envRoot.accentLight : envRoot.cardBg
//             border.color: parent.hovered ? envRoot.accentColor : envRoot.borderColor
//             border.width: parent.hovered ? 2 : 1
//             radius: 8
//         }
//         contentItem: Text {
//             text: "⚙ Configure Weather Conditions"
//             color: envRoot.textColor
//             font.bold: true
//             font.pixelSize: 13
//             horizontalAlignment: Text.AlignHCenter
//             verticalAlignment: Text.AlignVCenter
//         }
//         onClicked: weatherWin.open()
//     }

//     // --- 3. ATMOSPHERE & FOG BUTTON ---
//     Button {
//         Layout.fillWidth: true
//         Layout.preferredHeight: 50
//         background: Rectangle {
//             color: parent.down ? envRoot.accentLight : envRoot.cardBg
//             border.color: parent.hovered ? envRoot.accentColor : envRoot.borderColor
//             border.width: parent.hovered ? 2 : 1
//             radius: 8
//         }
//         contentItem: Text {
//             text: "⚙ Configure Atmosphere & Fog"
//             color: envRoot.textColor
//             font.bold: true
//             font.pixelSize: 13
//             horizontalAlignment: Text.AlignHCenter
//             verticalAlignment: Text.AlignVCenter
//         }
//         onClicked: atmosphereWin.open()
//     }

//     // --- 4. WIND & WAVES (Detailed) ---
//     GroupBox {
//         title: "Wind & Waves"
//         Layout.fillWidth: true
//         font.pixelSize: 14; font.bold: true
//         background: Rectangle { color: envRoot.cardBg; border.color: envRoot.borderColor; radius: 8 }

//         ColumnLayout {
//             anchors.fill: parent; spacing: 14

//             RowLayout {
//                 Layout.fillWidth: true
//                 Text { text: "Wind Speed"; font.pixelSize: 12; color: envRoot.textMuted; Layout.fillWidth: true }
//                 Text { text: windSpeedSlider.value.toFixed(1) + " kts"; font.pixelSize: 13; font.bold: true; color: envRoot.accentColor }
//             }
//             ModernSlider { id: windSpeedSlider; from: 0; to: 60; value: 5.0; Layout.fillWidth: true }

//             RowLayout {
//                 Text { text: "Wind Dir (°):"; Layout.fillWidth: true; font.pixelSize: 12; color: envRoot.textMuted }
//                 SpinBox { id: windDirSpin; from: 0; to: 359; value: 0 }
//             }

//             Rectangle { Layout.fillWidth: true; height: 1; color: envRoot.borderColor; Layout.margins: 4 }

//             RowLayout {
//                 Layout.fillWidth: true
//                 Text { text: "Wave Height"; font.pixelSize: 12; color: envRoot.textMuted; Layout.fillWidth: true }
//                 Text { text: waveHeightSlider.value.toFixed(1) + " m"; font.pixelSize: 13; font.bold: true; color: envRoot.accentColor }
//             }
//             ModernSlider { id: waveHeightSlider; from: 0; to: 15; value: 0.3; Layout.fillWidth: true }

//             ModernCheckBox { id: sameDirCheck; text: "Waves follow wind"; checked: true }

//             RowLayout {
//                 enabled: !sameDirCheck.checked; opacity: enabled ? 1.0 : 0.5
//                 Text { text: "Wave Dir (°):"; Layout.fillWidth: true; font.pixelSize: 12; color: envRoot.textMuted }
//                 SpinBox { id: waveDirSpin; from: 0; to: 359; value: 0 }
//             }
//         }
//     }

//     // --- 5. HYDRO-ACOUSTICS & TIDES ---
//     GroupBox {
//         title: "Currents & Hydro-Acoustics"
//         Layout.fillWidth: true
//         font.pixelSize: 14; font.bold: true
//         background: Rectangle { color: envRoot.cardBg; border.color: envRoot.borderColor; radius: 8 }

//         ColumnLayout {
//             anchors.fill: parent; spacing: 14

//             RowLayout {
//                 Layout.fillWidth: true
//                 Text { text: "Current Speed"; font.pixelSize: 12; color: envRoot.textMuted; Layout.fillWidth: true }
//                 Text { text: currentSpeedSlider.value.toFixed(1) + " kn"; font.pixelSize: 13; font.bold: true; color: envRoot.accentColor }
//             }
//             ModernSlider { id: currentSpeedSlider; from: 0; to: 10; value: 1.2; Layout.fillWidth: true }

//             RowLayout {
//                 Text { text: "Current Dir (°):"; Layout.fillWidth: true; font.pixelSize: 12; color: envRoot.textMuted }
//                 SpinBox { id: currentDirSpin; from: 0; to: 359; value: 180; editable: true }
//             }

//             Rectangle { Layout.fillWidth: true; height: 1; color: envRoot.borderColor; Layout.margins: 4 }

//             RowLayout {
//                 Layout.fillWidth: true
//                 Text { text: "Tide Height"; font.pixelSize: 12; color: envRoot.textMuted; Layout.fillWidth: true }
//                 Text { text: tideSlider.value.toFixed(1) + " m"; font.pixelSize: 13; font.bold: true; color: envRoot.accentColor }
//             }
//             ModernSlider { id: tideSlider; from: -5; to: 15; value: 2.5; Layout.fillWidth: true }

//             RowLayout {
//                 Layout.fillWidth: true
//                 Text { text: "Sonic Speed"; font.pixelSize: 12; color: envRoot.textMuted; Layout.fillWidth: true }
//                 Text { text: sonicSpeedSlider.value.toFixed(0) + " m/s"; font.pixelSize: 13; font.bold: true; color: envRoot.accentColor }
//             }
//             ModernSlider { id: sonicSpeedSlider; from: 1400; to: 1600; value: 1500; Layout.fillWidth: true }
//         }
//     }

//     GroupBox {
//         title: "Seabed & Bottom Conditions"
//         Layout.fillWidth: true
//         background: Rectangle { color: envRoot.cardBg; border.color: envRoot.borderColor; radius: 8 }

//         ColumnLayout {
//             anchors.fill: parent; spacing: 14

//             Text { text: "Seabed Type"; font.pixelSize: 12; color: envRoot.textMuted }
//             ModernComboBox {
//                 id: seabedCombo
//                 model: ["Sand", "Mud", "Rock", "Clay", "Gravel"] // Common maritime seabed types
//                 Layout.fillWidth: true
//             }

//             Rectangle { Layout.fillWidth: true; height: 1; color: envRoot.borderColor }

//             Text { text: "Muddy Strata"; font.bold: true; font.pixelSize: 13 }

//             RowLayout {
//                 Text { text: "Thickness (m)"; Layout.fillWidth: true; font.pixelSize: 12; color: envRoot.textMuted }
//                 Text { text: muddyThicknessSlider.value.toFixed(1); font.bold: true; color: envRoot.accentColor }
//             }
//             ModernSlider { id: muddyThicknessSlider; from: 0; to: 10; value: 0 }

//             RowLayout {
//                 Text { text: "Density (kg/m³)"; Layout.fillWidth: true; font.pixelSize: 12; color: envRoot.textMuted }
//                 Text { text: muddyDensitySlider.value.toFixed(0); font.bold: true; color: envRoot.accentColor }
//             }
//             ModernSlider { id: muddyDensitySlider; from: 1000; to: 2000; value: 1200 }
//         }
//     }

//     // --- 6. SEA VISUALS ---
//     GroupBox {
//         title: "Visual Effects"
//         Layout.fillWidth: true
//         font.pixelSize: 14; font.bold: true
//         background: Rectangle { color: envRoot.cardBg; border.color: envRoot.borderColor; radius: 8 }

//         GridLayout {
//             columns: 2; anchors.fill: parent; rowSpacing: 12
//             ModernCheckBox { id: whitecapsCheck; text: "Whitecaps"; checked: true }
//             ModernCheckBox { id: foamCheck; text: "Foam"; checked: true }
//             ModernCheckBox { id: dropsCheck; text: "Rain on Glass"; checked: false }
//         }
//     }

//     // --- 7. GLOBAL APPLY BUTTON ---
//     Button {
//         id: updateBtn
//         text: "UPDATE SIMULATION"
//         Layout.fillWidth: true
//         Layout.preferredHeight: 52
//         Layout.topMargin: 10

//         scale: down ? 0.98 : 1.0
//         Behavior on scale { NumberAnimation { duration: 100 } }

//         background: Rectangle {
//             color: updateBtn.down ? "#0090cc" : (updateBtn.hovered ? "#00a8ff" : envRoot.accentColor)
//             radius: 8
//             Behavior on color { ColorAnimation { duration: 150 } }
//         }

//         contentItem: Text {
//             text: updateBtn.text
//             color: "white"
//             font.bold: true
//             font.pixelSize: 14
//             font.letterSpacing: 1.2
//             horizontalAlignment: Text.AlignHCenter
//             verticalAlignment: Text.AlignVCenter
//             opacity: updateBtn.down ? 0.8 : 1.0
//         }

//         onClicked: envRoot.applyAll()
//     }
// }
