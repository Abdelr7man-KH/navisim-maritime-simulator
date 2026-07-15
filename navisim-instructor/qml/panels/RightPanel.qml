import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes

ScrollView {
    id: rightPanel
    clip: true
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    ScrollBar.vertical.policy: ScrollBar.AsNeeded

    property int activeTab: 0

    contentWidth: availableWidth

    Rectangle {
        id: bgRect
        implicitWidth: 350
        implicitHeight: contentColumn.implicitHeight + 20
        color: "#ffffff"
        border.color: "#e2e8f0"

        ColumnLayout {
            id: contentColumn
            anchors.fill: parent
            spacing: 0

            // ---------------- TAB BAR (REFACTORED) ----------------
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                spacing: 0

                Repeater {
                    model: ["Monitoring", "Log", "Chat"]

                    // We use Rectangle instead of Button to avoid style errors
                    Rectangle {
                        id: tabItem
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "white"

                        // Property to check if this tab is currently selected
                        property bool isSelected: (panelManager.rightSection === modelData.toLowerCase())

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            font.pixelSize: 14
                            // Vivid colors for the active tab
                            color: tabItem.isSelected ? "#0ea5e9" : "#64748b"
                            font.bold: tabItem.isSelected
                        }

                        // Blue selection indicator at the bottom
                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: 3
                            color: tabItem.isSelected ? "#0ea5e9" : "transparent"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                rightPanel.activeTab = index;
                                let sectionName = modelData.toLowerCase();
                                panelManager.openRight(sectionName);
                                panelManager.rightOpen = true;
                                panelManager.rightSection = sectionName;
                            }
                        }
                    }
                }
            }

            // ================= MONITORING CONTENT =================
            ColumnLayout {
                id: monitoringView
                visible: rightPanel.activeTab === 0
                Layout.fillWidth: true
                spacing: 0

                // OWN SHIP DATA
                ColumnLayout {
                    Layout.margins: 15
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: "OWN SHIP DATA"
                        font.bold: true
                        color: "#64748b"
                        font.pixelSize: 12
                    }

                    GridLayout {
                        columns: 2
                        columnSpacing: 12
                        rowSpacing: 12
                        Layout.fillWidth: true

                        Repeater {
                            model: [
                                { label: "HDG (GYRO)", val: "019.4°" },
                                { label: "STW", val: "13.6 kn" },
                                { label: "COG", val: "021.0°" },
                                { label: "SOG", val: "13.8 kn" }
                            ]

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 70
                                radius: 8
                                border.color: "#e2e8f0"
                                color: "#f8fafc"

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 2

                                    Text {
                                        text: modelData.label
                                        font.pixelSize: 10
                                        color: "#94a3b8"
                                        font.bold: true
                                    }

                                    Text {
                                        text: modelData.val
                                        font.pixelSize: 20
                                        font.bold: true
                                        color: "#1e293b"
                                    }
                                }
                            }
                        }
                    }
                }

                // PROPULSION & STEERING
                ColumnLayout {
                    Layout.margins: 15
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "PROPULSION & STEERING"
                        font.bold: true
                        color: "#64748b"
                        font.pixelSize: 12
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 180
                        radius: 8
                        border.color: "#e2e8f0"

                        Item {
                            width: 180
                            height: 120
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: 10

                            Shape {
                                anchors.fill: parent
                                ShapePath {
                                    strokeColor: "#64748b"
                                    strokeWidth: 6
                                    fillColor: "transparent"
                                    capStyle: ShapePath.RoundCap

                                    PathAngleArc {
                                        centerX: 90
                                        centerY: 90
                                        radiusX: 75
                                        radiusY: 75
                                        startAngle: 180
                                        sweepAngle: 180
                                    }
                                }
                            }

                            Rectangle {
                                width: 3
                                height: 60
                                color: "#ef4444"
                                x: 90 - 1.5
                                y: 30
                                transform: Rotation {
                                    origin.x: 1.5
                                    origin.y: 60
                                    angle: 15
                                }
                            }

                            Text {
                                text: "15° Stbd"
                                font.pixelSize: 18
                                font.bold: true
                                color: "#0ea5e9"
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }
                }

                // ECHO SOUNDER
                ColumnLayout {
                    Layout.margins: 15
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "ECHO SOUNDER"
                        font.bold: true
                        color: "#64748b"
                        font.pixelSize: 12
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 80
                        radius: 8
                        color: "#0f172a"
                        clip: true

                        Text {
                            text: "11.6 m"
                            color: "#22c55e"
                            font.pixelSize: 26
                            font.bold: true
                            anchors.centerIn: parent
                        }
                    }
                }
            }

            // ================= LOG CONTENT =================
            ColumnLayout {
                visible: rightPanel.activeTab === 1
                Layout.margins: 15
                Layout.fillWidth: true
                Text { text: "EVENT LOG"; font.bold: true; color: "#1e293b" }
            }

            // ================= CHAT CONTENT =================
            ColumnLayout {
                visible: rightPanel.activeTab === 2
                Layout.margins: 15
                Layout.fillWidth: true
                Text { text: "INSTRUCTOR CHAT"; font.bold: true; color: "#1e293b" }
            }

            Item { Layout.fillHeight: true }
        }
    }
}
