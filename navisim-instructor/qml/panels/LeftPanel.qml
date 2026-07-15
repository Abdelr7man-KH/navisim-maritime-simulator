import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

ScrollView {
    id: leftPanel
    clip: true
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    ScrollBar.vertical.policy: ScrollBar.AsNeeded

    signal addVessleClicked()

    property string section: "environment"
    contentWidth: availableWidth
    property var mapModelBackend: null
    property ListModel vesselListModel: ListModel {}

    Rectangle {
        id: backgroundRect
        implicitWidth: 320
        implicitHeight: contentColumn.implicitHeight + 40
        color: "#f8fafc"
        border.color: "#cbd5e1"

        ColumnLayout {
            id: contentColumn
            anchors.fill: parent
            anchors.margins: 16
            spacing: 20

            Text {
                text: section.toUpperCase()
                font.bold: true
                color: "#64748b"
                font.pixelSize: 12
                Layout.bottomMargin: -10
            }

            Loader {
                id: panelLoader
                Layout.fillWidth: true
                sourceComponent: {
                    if (section === "environment") return environmentComponent;
                    if (section === "incidents") return incidentsPanel;
                    if (section === "traffic") return trafficPanel;
                    if (section === "camera") return cameraPanel;
                    return null;
                }
                Connections{
                    target: panelLoader.item
                    ignoreUnknownSignals: true
                    function onAddVessleClicked(){
                        leftPanel.addVessleClicked()
                    }
                }
            }

            Item { Layout.fillHeight: true }
        }
    }

    // --- SHARED REUSABLE "PURE" COMPONENTS ---

    component IncidentButton : Rectangle {
        id: incBtn
        property string icon: ""
        property string label: ""
        property color baseColor: "#fff1f2"
        property color activeColor: "#ef4444"
        property color hoverBorder: "#fca5a5"
        property bool checkable: false
        property bool checked: false
        signal clicked()

        Layout.fillWidth: true
        Layout.preferredHeight: 70
        radius: 6

        // 1. Updated Background Color Logic to support 'checked' state
        color: incBtnMouse.pressed ? "#1d4ed8" :
               (incBtn.checked ? activeColor :
               (incBtnMouse.containsMouse ? "#F9A290" : baseColor))

        // 2. Updated Border Color Logic to support 'checked' state
        border.color: incBtnMouse.pressed ? "#3b82f6" :
                      (incBtn.checked ? activeColor :
                      (incBtnMouse.containsMouse ? "#F67D65" : hoverBorder))

        scale: incBtnMouse.pressed ? 0.95 : 1.0
        Behavior on scale { NumberAnimation { duration: 100 } }
        Behavior on color { ColorAnimation { duration: 150 } }

        Column {
            anchors.centerIn: parent
            spacing: 4
            Text { text: incBtn.icon; anchors.horizontalCenter: parent.horizontalCenter; font.pixelSize: 16 }
            Text {
                text: incBtn.label
                // 3. Update text color so it stays readable (white) when checked
                color: (incBtnMouse.pressed || incBtn.checked || incBtnMouse.containsMouse) ? "white" : activeColor
                font.pixelSize: 11; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        MouseArea {
            id: incBtnMouse;
            anchors.fill: parent;
            hoverEnabled: true

            // 4. This block was missing and is required to make onClicked work
            onClicked: {
                if (incBtn.checkable) {
                    incBtn.checked = !incBtn.checked // Toggles true/false
                }
                incBtn.clicked() // Emits the clicked signal to the parent instantiation
            }
        }
    }


    // --- PANELS ---

    Component {
        id: environmentComponent
        EnvironmentPanel { }
    }

    Component {
        id: incidentsPanel
        GridLayout {
            columns: 2
            rowSpacing: 10
            columnSpacing: 10

            IncidentButton { icon: "⚠️";
                label: "Engine Fail"
                checkable: true
                onClicked:{
                    console.log("Clicked")
                    if(checked)
                        physicsBridge.sendControlCommand("ENGINE_FAILURE")
                    else
                        physicsBridge.sendControlCommand("ENGINE_START")
                }
            }
            IncidentButton {
                icon: "📡"; label: "GPS Lost";
                activeColor: "#d97706"; hoverBorder: "#fcd34d"
            }
            IncidentButton {
                icon: "🚢"; label: "Steering Fail";
                activeColor: "#1e293b"; baseColor: "white"; hoverBorder: "#cbd5e1"
            }
            IncidentButton {
                icon: "🔥"; label: "Fire Alarm";
                activeColor: "#1e293b"; baseColor: "white"; hoverBorder: "#cbd5e1"
            }
        }
    }

    Component {
        id: trafficPanel
        ColumnLayout {
            spacing: 10
            width: parent ? parent.width : 300

            // Add Vessel Text Link
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                Text {
                    anchors.right: parent.right
                    text: "+ Add Vessel"
                    color: addVesselMouse.containsMouse ? "#0090cc" : "#0ea5e9"
                    font.bold: true
                    font.pixelSize: 13
                }
                MouseArea {
                    id: addVesselMouse;
                    anchors.fill: parent;
                    hoverEnabled: true
                    onClicked: leftPanel.addVessleClicked()
                }
            }

        ColumnLayout{
            Layout.fillWidth: true
            spacing: 8
                Repeater {
                    model: leftPanel.vesselListModel
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 45
                        radius: 6
                        //border.color: "#e2e8f0"
                        //color: "white"
                        property bool isPrimaryShip: leftPanel.mapModelBackend && leftPanel.mapModelBackend.primaryShip && (leftPanel.mapModelBackend.primaryShip.name === model.shipName)
                        border.color: isPrimaryShip ? "#0ea5e9" : "#e2e8f0"
                        border.width: isPrimaryShip ? 2 : 1
                        color: isPrimaryShip ? "#f0f9ff" : "white"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8

                            // Use the shipColor defined in the editor
                            Rectangle { width: 8; height: 8; radius: 4; color: model.shipColor || "#22c55e" }

                            // Dynamically use the ship name
                            Text {
                                text: model.shipName + (isPrimaryShip ? " (HQ)" : "")
                                Layout.fillWidth: true
                                font.bold: true
                                font.pixelSize: 12
                                elide: Text.ElideRight // Truncates text with "..." if the name is too long
                            }

                            // btn-1
                            Rectangle {
                                id: plotVis
                                property bool checked: true
                                width: 50; height: 26; radius: 4
                                color: btn1Mouse.containsMouse ? "#e2e8f0" : "#f1f5f9"
                                border.color: "#cbd5e1"
                                Text { text: "dot"; anchors.centerIn: parent; font.pixelSize: 10; color: "#334155"; font.bold: true }
                                MouseArea { id: btn1Mouse; anchors.fill: parent; hoverEnabled: true; onClicked: {
                                        simView.mapModel.setVisibiltyPlot(plotVis.checked)
                                        plotVis.checked = !(plotVis.checked)
                                    } }
                            }
                            // btn-2
                            Rectangle {
                                id: trackVis
                                property bool checked: true
                                width: 50; height: 26; radius: 4
                                color: btn2Mouse.containsMouse ? "#e2e8f0" : "#f1f5f9"
                                border.color: "#cbd5e1"
                                Text { text: "track"; anchors.centerIn: parent; font.pixelSize: 10; color: "#334155"; font.bold: true }
                                MouseArea { id: btn2Mouse; anchors.fill: parent; hoverEnabled: true; onClicked:{
                                        simView.mapModel.setVisibiltyTrack(!(trackVis.checked))
                                        trackVis.checked = !(trackVis.checked)
                                    } }
                            }
                            Rectangle {
                                id: trendVis
                                property bool checked: true
                                width: 50; height: 26; radius: 4
                                color: btn3Mouse.containsMouse ? "#e2e8f0" : "#f1f5f9"
                                border.color: "#cbd5e1"
                                Text { text: "trend"; anchors.centerIn: parent; font.pixelSize: 10; color: "#334155"; font.bold: true }
                                MouseArea { id: btn3Mouse; anchors.fill: parent; hoverEnabled: true; onClicked: {
                                    simView.mapModel.setVisibiltyTrend(!(trendVis.checked))
                                        trendVis.checked = !(trendVis.checked)
                                    } }
                            }
                        }
                    }
                }
            }
        }
    }


    Component {
            id: cameraPanel
            ColumnLayout {
                spacing: 15
                width: parent ? parent.width : 300
                // 2. DYNAMICALLY GENERATE ROWS FOR EACH VESSEL
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 10
                        Repeater {
                            model: leftPanel.vesselListModel
                            delegate: RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                // Store the outer index so it doesn't get overwritten by the inner Repeater
                                //property int shipIndex: index
                                property string currentShipName: model.shipName

                                // Ship Label
                                Text {
                                    text: currentShipName
                                    color: "#1e293b"
                                    font.bold: true
                                    font.pixelSize: 12
                                    Layout.preferredWidth: 70 // Keeps labels perfectly aligned vertically
                                    elide: Text.ElideRight

                                    MouseArea {
                                        id: camMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            root.globalCameraLockClick(currentShipName);}
                                    }
                                }


                                // 3 Horizontal Buttons
                                Repeater {
                                    model: ["Bridge View", "Bow View", "Stern View"]
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 30
                                        radius: 4
                                        color: camMouse.pressed ? "#cbd5e1" : (camMouse.containsMouse ? "#e2e8f0" : "#f1f5f9")
                                        border.color: "#94a3b8"

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData
                                            font.pixelSize: 9
                                            font.bold: true
                                            color: "#334155"
                                        }
                                        MouseArea {
                                            id: camMouse2
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: globalCameraLockClick(modelData)
                                        }
                                    }
                                }

                        }
        }

                Text {
                    text: "Elevation Control"
                    color: "#64748b"
                    font.pixelSize: 11
                    Layout.topMargin: 10
                }

                // Pure QML Slider
                Item {
                    id: elevSlider
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    property real value: 50

                    Rectangle {
                        width: parent.width; height: 6; radius: 3; color: "#e2e8f0"
                        anchors.verticalCenter: parent.verticalCenter
                        Rectangle {
                            width: (elevSlider.value / 100) * parent.width
                            height: parent.height; color: "#0ea5e9"; radius: 3
                        }
                    }
                    Rectangle {
                        width: 20; height: 20; radius: 10; color: "white"
                        border.color: "#0ea5e9"; border.width: 4
                        x: (elevSlider.value / 100) * (parent.width - width)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    MouseArea {
                        anchors.fill: parent
                        onPositionChanged: (mouse) => {
                            let pos = Math.max(0, Math.min(mouse.x, width))
                            elevSlider.value = (pos / width) * 100
                        }
                    }
                }
            }
        }
    }
}
