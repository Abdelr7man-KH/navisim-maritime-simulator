import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: topBar
    height: 100
    color: "#ffffff"
    border.color: "#cbd5e1"
    border.width: 1
    anchors.left: parent.left
    anchors.right: parent.right

    property string currentScenario: "None"
    property alias chartMapView: chartScaleSelector.mapView
    property alias chartMapModel: chartScaleSelector.mapModel
    property alias zoomAreaButton: zoomAreaBtn
    property alias centerModeButton: centerBtn
    signal centerModeButtonClicked()

    signal zoomInRequested()
    signal zoomOutRequested()
    signal measureButtonClicked()
    signal addMapButtonClicked()
    signal importScenarioButtonClicked()
    signal saveScenarioButtonClicked()

    //start and pause button
    signal startSessionRequested(int state)
    signal pauseSessionRequested(int state)

    signal zoomAreaButtonClicked(bool isActive) // Pass the state through the signal

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // --- ROW 1: Branding, Menus, and Session Controls ---
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 55
            Layout.leftMargin: 20
            Layout.rightMargin: 20
            spacing: 15

            // Logo Section
            RowLayout {
                spacing: 10
                Text {
                    text: "NAVI-<font color='#0ea5e9'>SIM</font>"
                    font.pixelSize: 16; font.bold: true; color: "#475569"
                    textFormat: Text.StyledText
                }
            }

            Rectangle { width: 1; height: 25; color: "#cbd5e1"; Layout.leftMargin: 5 }

            // Menu Buttons (Replaced 'Button' with 'Rectangle' + 'MouseArea')
            RowLayout {
                spacing: 2
                Repeater {
                    model: ["File", "Edit", "Chart", "View", "Window"]
                    Rectangle {
                        id: menuBtnRect
                        implicitWidth: 55
                        implicitHeight: 35
                        radius: 4
                        color: menuMouse.containsMouse ? "#f1f5f9" : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            font.pixelSize: 13
                            color: menuMouse.containsMouse ? "#0ea5e9" : "#1e293b"
                        }

                        MouseArea {
                            id: menuMouse
                            anchors.fill: parent
                            hoverEnabled: true
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true } // Spacer

            // Clock & End Session
            RowLayout {
                // End Session Button (Replaced 'Button' with 'Rectangle' + 'MouseArea')
                // --- START SESSION BUTTON ---
                Rectangle {
                    id: startSessionBtn
                    width: 100
                    height: 32
                    radius: 6
                    // Green color palette
                    color: startSessionMouse.containsMouse ? "#16a34a" : "#22c55e"

                    Text {
                        anchors.centerIn: parent
                        text: "▶ Start"
                        color: "white"
                        font.bold: true
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: startSessionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: physicsBridge.sendControlCommand("START")
                    }
                }

                // --- PAUSE SESSION BUTTON ---
                Rectangle {
                    id: pauseSessionBtn
                    width: 100
                    height: 32
                    radius: 6
                    // Amber/Orange color palette
                    color: pauseSessionMouse.containsMouse ? "#d97706" : "#f59e0b"

                    Text {
                        anchors.centerIn: parent
                        text: "⏸ Pause"
                        color: "white"
                        font.bold: true
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: pauseSessionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: physicsBridge.sendControlCommand("PAUSE")
                    }
                }
            }
        }

        // --- HORIZONTAL DIVIDER ---
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#e2e8f0"
        }

        // --- ROW 2: Icon Toolbar ---
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            Layout.leftMargin: 20
            spacing: 10

            ToolbarButton {
                iconPath: "qrc:/icons/new-project.svg";
                toolTip: "New Project";
                onClicked: topBar.addMapButtonClicked()
            }
            ToolbarButton {
                iconPath: "qrc:/icons/load-scenario.svg";
                toolTip: "Load Scenario"
                onClicked: topBar.importScenarioButtonClicked();
            }
            ToolbarButton { iconPath: "qrc:/icons/save-state.svg"; toolTip: "Save State" }

            VerticalDivider {}

            ToolbarButton { iconPath: "qrc:/icons/select.svg"; toolTip: "Selection Tool" }
            ToolbarButton {
                iconPath: "qrc:/icons/ruler.svg";
                toolTip: "Measure Distance";
                onClicked: topBar.measureButtonClicked()
            }
            ToolbarButton {
                id: zoomAreaBtn // Ensure this ID is unique!
                iconPath: "qrc:/icons/zoom-area.svg"
                toolTip: "Zoom Area"
                checkable: true
                onCheckedChanged: {
                    topBar.zoomAreaButtonClicked(checked)
                }
                }
            ToolbarButton {
                iconPath: "qrc:/icons/zoom-in.svg"
                toolTip: "Zoom In"
                onClicked: topBar.zoomInRequested()
            }
            ToolbarButton {
                iconPath: "qrc:/icons/zoom-out.svg"
                toolTip: "Zoom Out"
                onClicked: topBar.zoomOutRequested()
            }
            ToolbarButton {
                id: centerBtn
                iconPath: "qrc:/icons/log.svg" // Use an appropriate icon
                toolTip: "Toggle Chart Centering (Ctrl+Alt+C)"
                checkable: true
                onClicked: topBar.centerModeButtonClicked()
            }

            ChartScaleSelector{
                id:chartScaleSelector
            }
            VerticalDivider {}
            RowLayout{
                spacing: 2
                ToolbarButton {
                    id: recordBtn
                    iconPath: "qrc:/icons/record.svg" // Use an appropriate icon
                    toolTip: "Toggle Chart Centering (Ctrl+Alt+C)"
                    checkable: true
                    onCheckedChanged:{
                        if(checked){
                            playBtn.checked = false;
                            statusText.text="Status: <font color='#eb3150'>Recording</font>"
                            physicsBridge.sendControlCommand("RECORD_START")
                        }else{
                            topBar.saveScenarioButtonClicked()
                            statusText.text= "Status: <font color='#4ed45c'>Live</font>"
                        }

                    }
                }
                ToolbarButton {
                    id: playBtn
                    iconPath: "qrc:/icons/play.svg" // Use an appropriate icon
                    toolTip: "Start Scenario"
                    checkable: true
                    onCheckedChanged: {
                        if(checked){
                            recordBtn.checked = false;
                            statusText.text="Status: <font color='#319aeb'>Playing Scenario</font>"
                            physicsBridge.sendControlCommand("REPLAY_START")
                        }else{
                            statusText.text= "Status: <font color='#4ed45c'>Live</font>"
                            physicsBridge.sendControlCommand("LIVE");
                        }


                    }
                }
                FontLoader{
                    id: fonty
                    source: "qrc:/fonts/BoldFont.otf"
                }
                Text {
                    id: statusText
                    font.family: fonty.name
                    font.pixelSize: 17
                    topPadding: 5
                    leftPadding: 10
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: {
                        statusText.text = "Status: <font color='#4ed45c'>   Live</font>"
                    }
                }
            }
            VerticalDivider {}
            Text {
                id: currentScenarioText
                font.family: fonty.name
                font.pixelSize: 17
                topPadding: 5
                leftPadding: 10
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: "Current Scenario: " + "<font color='#4ed45c'>"+ currentScenario+"</font>"
            }
            VerticalDivider {}
            Item { Layout.fillWidth: true }
        }


    // --- REUSABLE COMPONENTS ---
    component VerticalDivider : Rectangle {
        width: 1; height: 20; color: "#cbd5e1"; Layout.leftMargin: 5; Layout.rightMargin: 5
    }

    component ToolbarButton : Item {
        id: btnRoot
        property url iconPath: ""
        property string toolTip: ""
        property bool checkable: false // New property
        property bool checked: false   // New property
        signal clicked()

        implicitWidth: 32; implicitHeight: 32

        Rectangle {
            anchors.fill: parent
            radius: 4
            // Logic: Blue if checked, gray if hovered, transparent otherwise
            color: btnRoot.checked ? "#0ea5e9" : (mouseArea.containsMouse ? "#f1f5f9" : "transparent")
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        Image {
            source: btnRoot.iconPath
            anchors.centerIn: parent
            sourceSize: Qt.size(20, 20)
            // Icon turns white if the background is blue (checked)
            opacity: btnRoot.checked ? 1.0 : (mouseArea.containsMouse ? 1.0 : 0.6)
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                // 3. INTERNAL TOGGLE: If checkable, flip the state
                if (btnRoot.checkable) {
                    btnRoot.checked = !btnRoot.checked
                }
                btnRoot.clicked()
            }
        }
        ToolTip.visible: mouseArea.containsMouse && toolTip !== ""; ToolTip.text: toolTip
    }
    component ChartScaleSelector : Item {
            id: chartSelectorRoot
            property var mapView: null
            property var mapModel: null
            property string textColor: "#0d6aff"
            property string borderColor: "#cbd5e1"
            property string backgroundColor: "#e9ebf0"
            // This binding points to the Q_PROPERTY in your C++ Display_s57_chart
            readonly property real currentScale: (mapModel && !isNaN(mapModel.currentMapScale) && mapModel.currentMapScale > 0)
                                                 ? mapModel.currentMapScale
                                                 : 10000
            readonly property var scaleValues: generateStandardScales()
            function generateStandardScales() {
                let scales = [];
                let current = 100;
                let max = 6000000;

                scales.push(current);

                while (current < max) {
                    // Dynamically calculate multiplier based on the length of the current number
                    // 100-999 -> mult=1 (step 50)
                    // 1000-9999 -> mult=2 (step 500)
                    // 10000-99999 -> mult=3 (step 5000)...
                    let mult = Math.floor(Math.log10(current)) - 1;
                    let step = 5 * (10 ** mult);

                    current += step;

                    // Prevent overshooting the 6,000,000 limit
                    if (current >= max) {
                        scales.push(max);
                        break;
                    }

                    scales.push(current);
                }

                return scales;
            }
            implicitWidth: 100
            implicitHeight: 30

            // This ensures the display updates if you zoom with mouse wheel
            Connections {
                target: chartSelectorRoot.mapView ? chartSelectorRoot.mapView : null
                function onMapScaleChanged() {
                    if (chartSelectorRoot.mapModel) {
                        chartSelectorRoot.mapModel.mapScaleChanged(); // Trigger C++ Notify
                    }
                }
            }

            Rectangle {
                id: scaleSelector
                anchors.fill: parent
                radius: 4; color: backgroundColor; border.color: borderColor; border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "1 : " + Number(chartSelectorRoot.currentScale).toLocaleString(Qt.locale(), 'f', 0)
                    color: textColor;
                    font.pixelSize: 11;
                    font.bold: true
                    font.family: "Courier New"
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: scaleDropdown.visible = !scaleDropdown.visible
                }

                Rectangle {
                    id: scaleDropdown
                    visible: false
                    width: 110
                    height: Math.min(scaleListView.count * 28, 280)
                    anchors.top: parent.bottom
                    anchors.topMargin: 4
                    anchors.right: parent.right
                    color: backgroundColor; border.color: borderColor; border.width: 1; radius: 4; z: 2000; clip: true

                    ListView {
                        id: scaleListView
                        anchors.fill: parent
                        model: scaleValues
                        delegate: Rectangle {
                            width: scaleListView.width; height: 28
                            color: delegateMouse.containsMouse ? "#334155" : "transparent"

                            readonly property bool isCurrent: Math.abs(chartSelectorRoot.currentScale - modelData) < modelData * 0.1
                            border.color: isCurrent ? borderColor : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "1 : " + Number(modelData).toLocaleString(Qt.locale(), 'f', 0)
                                color: isCurrent ? textColor : textColor; font.pixelSize: 11
                            }

                            MouseArea {
                                id: delegateMouse; anchors.fill: parent; hoverEnabled: true
                                onClicked: {
                                    if (chartSelectorRoot.mapModel) {
                                        chartSelectorRoot.mapModel.setMapScale(modelData)
                                    }
                                    scaleDropdown.visible = false
                                }
                            }
                        }
                    }
                }
            }

            TapHandler {
                target: null
                enabled: scaleDropdown.visible
                onTapped: scaleDropdown.visible = false
            }
        }
    }
}
