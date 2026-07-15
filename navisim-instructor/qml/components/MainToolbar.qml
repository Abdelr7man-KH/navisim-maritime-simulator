    import QtQuick
    import QtQuick.Layouts
    import QtQuick.Controls
    Rectangle {
        id: toolbar
        height: 50
        color: "transparent" // Let the TopBar handle the background

        //Button signals
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            spacing: 15

            // GROUP 1: File Operations
            Row {
                spacing: 12
                ToolbarButton { iconText: "📄+"; toolTip: "New File" }
                ToolbarButton { iconText: "📂"; toolTip: "Open" }
                ToolbarButton { iconText: "💾"; toolTip: "Save" }
            }

            VerticalSeparator {}

            // GROUP 2: Navigation Tools
            Row {
                spacing: 12
                ToolbarButton {
                    iconText: "↗";
                    isActive: true // Highlighted in blue in your screenshot
                    toolTip: "Select"
                }
                ToolbarButton {
                    iconText: "📏";
                    toolTip: "Measure";
                }
                ToolbarButton { iconText: "🔍+"; toolTip: "Zoom In" }
                ToolbarButton { iconText: "🔍-"; toolTip: "Zoom Out" }
            }

            VerticalSeparator {}

            // GROUP 3: Environment & Vessel
            Row {
                spacing: 12
                ToolbarButton { iconText: "☁"; toolTip: "Weather" }
                ToolbarButton { iconText: "〰"; toolTip: "Sea State" }
                ToolbarButton { iconText: "🚢"; toolTip: "Vessel Info" }
            }

            VerticalSeparator {}

            // GROUP 4: Annotation
            Row {
                spacing: 12
                ToolbarButton { iconText: "Tt"; toolTip: "Add Text" }
                ToolbarButton { iconText: "⬠"; toolTip: "Draw Area" }
            }

            Item { Layout.fillWidth: true } // Spacer to push items to left
        }

        // --- Helper Components for the Toolbar ---

        component ToolbarButton : Control {
            id: btnControl
            property string iconText: ""
            property string toolTip: ""
            property bool isActive: true
            property bool checkable: false // Allows the button to stay active
            property bool checked: false   // Tracks the current state
            signal clicked()
            implicitWidth: 36
            implicitHeight: 36

            contentItem: Text {
                text: iconText
                font.pixelSize: 18
                color: (btnControl.checked || btnMouse.containsMouse) ? "#ffffff" : "#94a3b8"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            background: Rectangle {
                radius: 6
                color: btnControl.checked ? "#0ea5e9" : (btnMouse.containsMouse ? "#334155" : "transparent")
                Behavior on color { ColorAnimation { duration: 150 } }
            }
            MouseArea {
                id: btnMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    if (btnControl.checkable) {
                        btnControl.checked = !btnControl.checked // Toggle only if checkable
                    }
                    btnControl.clicked() // Always fire the click signal
                }
            }

            ToolTip.visible: btnMouse.containsMouse && toolTip !== ""
            ToolTip.text: toolTip
            ToolTip.delay: 400
        }

        component VerticalSeparator : Rectangle {
            width: 1
            height: 24
            color: "#334155"
            Layout.alignment: Qt.AlignVCenter
        }
    }
