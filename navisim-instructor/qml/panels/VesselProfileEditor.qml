// panels/VesselProfileEditor.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Popup {
    id: editorPopup
    width: 700
    height: 790
    modal: true
    focus: true
    anchors.centerIn: Overlay.overlay
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    property color selectedVesselColor: "#40E0D0"

    // Dim the background when this popup is open
    Overlay.modal: Rectangle {
        color: "#80000000" // 50% opacity black
    }

    signal applyVesselRequested(string shipName, string shipType, color shipColor)

    // Signal to notify main.qml to apply the boat placement
    //signal applyVesselRequested(string shipName, string shipType)

    background: Rectangle {
        color: "#f8fafc" // Light background matching your screenshots
        radius: 8
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 30
        spacing: 20

        // Header Titles
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 5
            Text {
                text: "Vessel Profile Editor"
                font.pixelSize: 18
                color: "#1e293b"
                Layout.alignment: Qt.AlignHCenter
            }
            Text {
                text: "Update technical specifications for simulation assets."
                font.pixelSize: 14
                color: "#64748b"
                Layout.alignment: Qt.AlignHCenter
            }
        }

        // Main Card
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#ffffff"
            radius: 8
            border.color: "#e2e8f0"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 25
                spacing: 15

                // Card Header (Ship Details)
                /*RowLayout {
                    Layout.fillWidth: true
                    Rectangle {
                        width: 20; height: 20; radius: 10; color: "#2563eb"
                        Text { text: "i"; color: "white"; anchors.centerIn: parent; font.bold: true; font.pixelSize: 12 }
                    }
                    Text {
                        text: "Ship Details"
                        font.pixelSize: 16
                        color: "#1e293b"
                        Layout.fillWidth: true
                    }
                    Text { text: "⌃"; color: "#64748b"; font.pixelSize: 18 } // Caret icon
                }*/

                // Divider
                Rectangle { Layout.fillWidth: true; height: 1; color: "#e2e8f0" }

                // Ship Image Placeholder (Replace with actual Image component later)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 200
                    color: "#cbd5e1"
                    radius: 4
                    clip: true
                    Text {
                        anchors.centerIn: parent
                        text: "Ship Image\n(Add your source here)"
                        horizontalAlignment: Text.AlignHCenter
                        color: "#64748b"
                    }
                    // TODO: Replace above with your actual image
                    // Image { source: "qrc:/path/to/ship.jpg"; anchors.fill: parent; fillMode: Image.PreserveAspectCrop }
                }

                // Inputs: Ship Name & Ship Type
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 20

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 5
                        Text { text: "SHIP NAME"; font.pixelSize: 10; font.bold: true; color: "#94a3b8" }
                        TextField {
                            id: nameField
                            text: "USS Atlantic"
                            Layout.fillWidth: true
                            background: Rectangle { border.color: "#e2e8f0"; radius: 4 }
                            padding: 10
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 5
                        Text { text: "OBJECT TYPE"; font.pixelSize: 10; font.bold: true; color: "#94a3b8" }
                        ComboBox {
                            id: typeCombo
                            Layout.fillWidth: true
                            model: ["Research Vessel", "Cargo Ship", "Oil Tanker"]
                            background: Rectangle { border.color: "#e2e8f0"; radius: 4 }
                        }
                    }
                }


                // 4. ADD THE COLOR PICKER SECTION HERE (Right below the Name/Type inputs)
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 5

                                    Text { text: "VESSEL IDENTIFICATION COLOR"; font.pixelSize: 10; font.bold: true; color: "#94a3b8" }

                                    RowLayout {
                                        spacing: 15

                                        // The Color Swatch Button
                                        Rectangle {
                                            id: colorPreviewSwatch
                                            width: 35
                                            height: 35
                                            radius: 6
                                            color: editorPopup.selectedVesselColor
                                            border.color: "#cbd5e1"
                                            border.width: 1

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: vesselColorDialog.open()
                                            }
                                        }

                                        Text {
                                            text: "Click swatch to pick a color"
                                            color: "#64748b"
                                            font.pixelSize: 12
                                        }
                                    }
                                }



                // Technical Description
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 5
                    Text { text: "TECHNICAL DESCRIPTION"; font.pixelSize: 10; font.bold: true; color: "#94a3b8" }
                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredHeight: 120
                        TextArea {
                            text: "Primary arctic research vessel equipped with Class III hull reinforcement and multibeam echosounder. Max speed 15 knots. Recent maintenance check: Completed June 2024. Active deployment in North Sea sector for mapping operations."
                            wrapMode: TextArea.Wrap
                            background: Rectangle { border.color: "#e2e8f0"; radius: 4 }
                            padding: 10
                        }
                    }
                }
            }
        }

        // Bottom Action Buttons
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignRight
            spacing: 20

            // Add Vessel Button
            Rectangle {
                width: 140
                height: 45
                color: addBtnMouse.pressed ? "#1d4ed8" : "#2563eb"
                radius: 4
                Text {
                    text: "ADD VESSEL"
                    color: "white"
                    font.bold: true
                    anchors.centerIn: parent
                }
                MouseArea {
                    id: addBtnMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        // 1. Emit the signal to apply the vessel
                        editorPopup.applyVesselRequested(nameField.text, typeCombo.currentText,editorPopup.selectedVesselColor)
                        // 2. Close the modal
                        editorPopup.close()
                    }
                }
            }
        }
    }

    ColorDialog {
            id: vesselColorDialog
            title: "Pick a vessel color"
            selectedColor: editorPopup.selectedVesselColor
            onAccepted: {
                // Update our UI swatch when the user hits OK on the wheel
                editorPopup.selectedVesselColor = selectedColor
            }
        }
}
