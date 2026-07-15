// panels/ShipTrackingEditor.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Popup {
    id: trackingPopup
    width: 680
    height: 720
    modal: true
    focus: true
    anchors.centerIn: Overlay.overlay
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    // State management for the tabs
    property string activeTarget: "Main"
    property color trackingLineColor: "#ef4444"

    // buffer
    property var targetData: {
        "Plotting": { "duration": 30, "period": 10, "timestampIdx": 1, "color": "#ef4444" },
        "Track": { "duration": 30, "period": 10, "timestampIdx": 1, "color": "#ef4444" },
        "Trend": { "duration": 30, "period": 10, "timestampIdx": 1, "color": "#ef4444" }
    }

    // Initialize UI when opening
    onOpened: {
        activeTarget = "Plotting"
        let data = targetData["Plotting"]
        durationSpin.value = data.duration
        periodSpin.value = data.period
        timestampCombo.currentIndex = data.timestampIdx
        trackingLineColor = data.color
    }

    Overlay.modal: Rectangle { color: "#80000000" }

    signal applyTrackingRequested(string target, int duration, int period, double timestamp, color trackColor)

    background: Rectangle {
        color: "#f8fafc"
        radius: 8
        border.color: "#cbd5e1"
    }

    // --- NEW: Top Right Close (X) Button ---
    Rectangle {
        z: 10
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 15
        width: 30
        height: 30
        radius: 15
        color: closeHoverArea.containsMouse ? "#e2e8f0" : "transparent"

        Text {
            text: "✕"
            anchors.centerIn: parent
            font.pixelSize: 16
            font.bold: true
            color: "#64748b"
        }

        MouseArea {
            id: closeHoverArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: trackingPopup.close()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 30
        spacing: 20

        // Header Section
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 4
            Text {
                text: "Vessel Track & Plotting Parameters"
                font.pixelSize: 18
                font.bold: true
                color: "#1e293b"
                Layout.alignment: Qt.AlignHCenter
            }
            Text {
                text: "Configure path history length, plot intervals, and vector mapping aesthetics."
                font.pixelSize: 13
                color: "#64748b"
                Layout.alignment: Qt.AlignHCenter
            }
        }

        // Main Card Base
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#ffffff"
            radius: 8
            border.color: "#e2e8f0"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 25
                spacing: 20

                // Target Selection Tabs (Segmented Control)
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    spacing: 0

                    Repeater {
                        model: ["Plotting", "Track", "Trend"]
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: trackingPopup.activeTarget === modelData ? "#2563eb" : "#f8fafc"
                            border.color: "#cbd5e1"
                            border.width: 1

                            Text {
                                text: modelData
                                anchors.centerIn: parent
                                color: trackingPopup.activeTarget === modelData ? "white" : "#64748b"
                                font.bold: true
                                font.pixelSize: 13
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    // 1. Save current UI values into the activeTarget entry
                                    targetData[trackingPopup.activeTarget] = {
                                        "duration": durationSpin.value,
                                        "period": periodSpin.value,
                                        "timestampIdx": timestampCombo.currentIndex,
                                        "color": trackingPopup.trackingLineColor
                                    }

                                    // 2. Switch the active target
                                    trackingPopup.activeTarget = modelData

                                    // 3. Load the values for the new activeTarget into the UI
                                    let newData = targetData[modelData]
                                    durationSpin.value = newData.duration
                                    periodSpin.value = newData.period
                                    timestampCombo.currentIndex = newData.timestampIdx
                                    trackingPopup.trackingLineColor = newData.color
                                }
                            }
                        }
                    }
                }

                // Graphic Vector/Contour Placeholder
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 160
                    color: "#cbd5e1"
                    radius: 6
                    clip: true

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: "Vessel Predictor & Past-Track Vectors"
                            font.bold: true
                            font.pixelSize: 13
                            color: "#475569"
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Text {
                            text: "(Displaying contour series, path histories, and historical intervals for " + trackingPopup.activeTarget + ")"
                            font.pixelSize: 11
                            color: "#64748b"
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }

                // Dual Inputs: Duration and Period
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 20

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 5
                        Text { text: "DURATION (MAX 120 MIN)"; font.pixelSize: 10; font.bold: true; color: "#94a3b8" }
                        SpinBox {
                            id: durationSpin
                            from: 0
                            to: 120
                            value: 30
                            Layout.fillWidth: true
                            editable: true

                            background: Rectangle {
                                implicitWidth: 140
                                implicitHeight: 40
                                border.color: "#e2e8f0"
                                radius: 4
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 5
                        Text { text: "PLOT INTERVAL / PERIOD (MAX 240 SEC)"; font.pixelSize: 10; font.bold: true; color: "#94a3b8" }
                        SpinBox {
                            id: periodSpin
                            from: 0
                            to: 240
                            value: 10
                            Layout.fillWidth: true
                            editable: true

                            background: Rectangle {
                                implicitWidth: 140
                                implicitHeight: 40
                                border.color: "#e2e8f0"
                                radius: 4
                            }
                        }
                    }
                }

                // Time Stamp Interval ComboBox
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5
                    Text { text: "TIME TAG STAMP INTERVAL"; font.pixelSize: 10; font.bold: true; color: "#94a3b8" }
                    ComboBox {
                        id: timestampCombo
                        Layout.fillWidth: true
                        model: ["0 min", "1.5 min", "10 min"]
                        currentIndex: 1

                        delegate: ItemDelegate {
                            width: timestampCombo.width
                            text: modelData
                            highlighted: timestampCombo.highlightedIndex === index
                            background: Rectangle {
                                color: highlighted ? "#f1f5f9" : "transparent"
                            }
                        }

                        background: Rectangle {
                            implicitHeight: 40
                            border.color: "#e2e8f0"
                            radius: 4
                        }
                    }
                }

                // Modernized Color Swatch Selector
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5
                    Text { text: "TRACK PIPELINE COLOR REPRESENTATION"; font.pixelSize: 10; font.bold: true; color: "#94a3b8" }

                    RowLayout {
                        spacing: 15
                        Rectangle {
                            id: colorPreviewSwatch
                            width: 36
                            height: 36
                            radius: 6
                            color: trackingPopup.trackingLineColor
                            border.color: "#cbd5e1"
                            border.width: 1

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: trackColorDialog.open()
                            }
                        }
                        Text {
                            text: "Click swatch box to alter current path render color mapping"
                            color: "#64748b"
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }

        // Action Buttons Setup
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignRight
            spacing: 12

            Rectangle {
                width: 100
                height: 42
                color: "transparent"
                border.color: "#cbd5e1"
                radius: 4
                Text { text: "CANCEL"; color: "#64748b"; font.bold: true; anchors.centerIn: parent }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: trackingPopup.close()
                }
            }

            Rectangle {
                width: 150
                height: 42
                color: applyBtnMouse.pressed ? "#1d4ed8" : "#2563eb"
                radius: 4
                Text { text: "SAVE CHANGES"; color: "white"; font.bold: true; anchors.centerIn: parent }
                MouseArea {
                    id: applyBtnMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        // 1. Update the local buffer for the active tab first
                        targetData[activeTarget] = {
                            "duration": durationSpin.value,
                            "period": periodSpin.value,
                            "timestampIdx": timestampCombo.currentIndex,
                            "color": trackingLineColor
                        }

                        // 2. Fetch the data strictly for the CURRENT tab
                        let data = targetData[activeTarget]
                        let tsVal = (data.timestampIdx === 1) ? 1.5 : (data.timestampIdx === 2 ? 10.0 : 0.0)

                        console.log("Applying Config for [", activeTarget, "] -> Duration:", data.duration,
                                    "Period:", data.period, "Timestamp:", tsVal, "Color:", data.color)

                        // 3. Emit the signal ONLY for the activeTarget
                        trackingPopup.applyTrackingRequested(
                            activeTarget,
                            data.duration,
                            data.period,
                            tsVal,
                            data.color
                        )

                        // Note: trackingPopup.close() removed here so the window stays open!
                    }
                }
            }
        }
    }

    ColorDialog {
        id: trackColorDialog
        title: "Pick a vessel tracking path color"
        selectedColor: trackingPopup.trackingLineColor
        onAccepted: {
            trackingPopup.trackingLineColor = selectedColor
        }
    }
}
