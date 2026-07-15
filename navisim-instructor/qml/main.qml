import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Dialogs
import "./components"
import "./panels"
import "./controls"
Window {
    id: root
    width: 1920
    height: 1080
    minimumWidth: 1280
    minimumHeight: 720
    visible: true
    color: "#0f172a"
    title: "Navi-Trainer Pro Simulation"

    PanelManager {
        id: panelManager
    }
    // 1. BACKGROUND LAYER (Simulation/Map)
    SimulationView {
        id: simView
        anchors.fill: parent
        z: 0
    }

    MapController {
            id: mapActions
            targetMapModel: simView.mapModel
        }
    Connections {
            target: simView.mapModel
            function onCenterModeActiveChanged() {
                topBar.centerModeButton.checked = simView.mapModel.centerModeActive
            }
    }



    // 2. INTERLAYS (Dim background when panels are open)
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: (panelManager.leftOpen || panelManager.rightOpen) ? 0.5 : 0.0
        visible: opacity > 0
        z: 50

        Behavior on opacity { NumberAnimation { duration: 200 } }

        MouseArea {
            anchors.fill: parent
            onClicked: panelManager.closePanels()
        }
    }

    // 3. UI LAYER (TopBar and Sidebars - Always on top of the dim layer)
    TopBar {
        id: topBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 100
        z: 150
        chartMapView: simView.mapControl
        chartMapModel: simView.mapModel

        onZoomInRequested: simView.mapModel.setMapScale(simView.mapModel.currentMapScale * 0.5)
        onZoomOutRequested: simView.mapModel.setMapScale(simView.mapModel.currentMapScale * 2.0)
        onMeasureButtonClicked: simView.mapModel.activateRuler()
        onAddMapButtonClicked: encFileDialog.open()
        onImportScenarioButtonClicked: scenarioFileDialog.open()
        onSaveScenarioButtonClicked: inputScenarioDialog.open()
        onZoomAreaButtonClicked: (isActive) => {
                    if (isActive) {
                        simView.mapModel.activateZoomArea()
                    } else {
                        simView.mapModel.deactivateZoomArea()
                    }
                }

        //forwarding request to msg broker
        onStartSessionRequested:function(state) {
            console.log("Sending command to broker:", state)

            // Assuming your NetworkBridge exposes a C_INVOKABLE method to send messages
            physicsBridge.send()
                }

        onPauseSessionRequested:function(state) {
            console.log("Sending command to broker:", state)
            physicsBridge.sendSessionCommand(state)
        }
        onCenterModeButtonClicked: {
            // Synchronize the C++ state with the button state
            simView.mapModel.centerModeActive = topBar.centerModeButton.checked
        }
    }
    FileDialog {
        id: encFileDialog
        title: "Select ENC CATALOG.031"
        nameFilters: ["ENC Catalog (CATALOG.031)", "All files (*)"]
        fileMode: FileDialog.OpenFile

        onAccepted: {
            // Pass selected file path to C++
            simView.mapModel.loadEncChart(selectedFile)
        }
    }
    FileDialog {
        id: scenarioFileDialog
        title: "Select Scenario .json"
        nameFilters: ["Scenario (*.json)", "All files (*)"]
        fileMode: FileDialog.OpenFile

        onAccepted: {
            // Pass selected file path to C++
            var fileUrlString = selectedFile.toString()
            var fileName = fileUrlString.split('/').pop()

            physicsBridge.sendScenarioCommand("LOAD_SCENARIO",fileName)
            topBar.currentScenario = fileName
            console.log("Load Scenario",fileName)
        }
    }
    Dialog{
        id: inputScenarioDialog
        title: "Enter Scenario Name"
        anchors.centerIn: parent
        modal: true // Blocks interaction with the background
        standardButtons: Dialog.Ok
        Column {
            spacing: 10
            width: 250

            Label {
                text: "Please enter a string:"
            }

            TextField {
                id: inputField
                width: parent.width
                placeholderText: "Type something..."
                focus: true // Focuses keyboard automatically when opened
            }
        }
        onAccepted: {
            // Triggered when OK is clicked
            physicsBridge.sendScenarioCommand("RECORD_STOP",inputField.text)
            // Clear the field for the next time it opens
            inputField.clear()
        }
    }

    // LEFT MINI SIDEBAR
    Rectangle {
        id: leftSidebar
        width: 45
        anchors.top: topBar.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        color: "#ffffff"
        z: 150

        Column {
                    anchors.centerIn: parent
                    spacing: 15 // Tightened spacing to fit all 7 icons nicely

                    // Original Left Icons
                    SidebarButton {
                                    iconPath: "../../icons/weather.svg"
                                    onClicked: panelManager.openLeft("environment")
                                    toolTipText:"weather"
                                }
                    SidebarButton { iconPath: "../../icons/incident.svg"; onClicked: panelManager.openLeft("incidents") }
                    SidebarButton { iconPath: "../../icons/vessel.svg"; onClicked: panelManager.openLeft("traffic") }
                    SidebarButton { iconPath: "../../icons/camera.svg"; onClicked: panelManager.openLeft("camera") }

                    // Divider between groups
                    Rectangle { width: 30; height: 1; color: "#e2e8f0"; anchors.horizontalCenter: parent.horizontalCenter }

                    // Moved from Right Sidebar
                    SidebarButton { iconPath: "../../icons/monitor.svg"; onClicked: panelManager.openRight("monitoring");toolTipText:"monitoring" }
                    SidebarButton { iconPath: "../../icons/centre.svg"; onClicked: trackingEditorDialog.open();toolTipText: "Ship Tracking Options" }

                }
    }

    // 4. SLIDING PANELS (Z: 100 - Below sidebars, above the map/dim)

    LeftPanel {
        id: leftPanel
        width: 340
        anchors.top: topBar.bottom
        anchors.bottom: parent.bottom
        // Slide out from behind the sidebar
        x: panelManager.leftOpen ? 60 : -width
        section: panelManager.leftSection
        z: 100
        Behavior on x {
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }

        onAddVessleClicked: {
                    // Open the new Editor UI instead of placing the vessel directly
                    vesselEditorDialog.open()
                }
    }

    RightPanel {
        id: rightPanel
        width: 350
        anchors.top: topBar.bottom
        anchors.bottom: parent.bottom
        // Slide out from the right side
        x: panelManager.rightOpen ? root.width - width - 60 : root.width

        // Convert the string section from Manager to the integer index for RightPanel
        activeTab: {
            if (panelManager.rightSection === "monitoring") return 0;
            if (panelManager.rightSection === "log") return 1;
            if (panelManager.rightSection === "chat") return 2;
            return 0;
        }

        z: 100

        Behavior on x {
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }
    }

    //start pause connections
    Connections {
        target: physicsBridge

        function onPositionChanged() {
            // Because of the 'Behavior' above, the animatedX/Y/Heading
            // values will slide smoothly to the new coordinates.
            simView.mapModel.movingWatercraft(physicsBridge.shipX,physicsBridge.shipY,physicsBridge.shipHeading,physicsBridge.shipSpeed)
        }
    }
    //NetworkBridge{
        //id:instructorRoot
        // property double animatedX: physicsBridge.shipX
        // property double animatedY: physicsBridge.shipY
        // property double animatedHeading: physicsBridge.shipHeading

        // // This is the "Magic" part
        // Behavior on animatedX { SmoothedAnimation { velocity: -1; duration: 100 } }
        // Behavior on animatedY { SmoothedAnimation { velocity: -1; duration: 100 } }
        // Behavior on animatedHeading { RotationAnimation { duration: 100; direction: RotationAnimation.Shortest } }
            //Connections {
              //  target: physicsBridge
                //function onPositionChanged() {
                    // Because of the 'Behavior' above, the animatedX/Y/Heading
                    // values will slide smoothly to the new coordinates.
                  //  simView.mapModel.movingWatercraft(physicsBridge.shipX,physicsBridge.shipY,physicsBridge.shipHeading,physicsBridge.shipSpeed)
               // }
            //}
        // id: shipManager

        //     // 1. These properties hold the 'target' from the network
        //     property double targetX: physicsBridge.shipX
        //     property double targetY: physicsBridge.shipY
        //     property double targetHeading: physicsBridge.shipHeading

        //     // 2. These properties smoothly 'chase' the target values
        //     // We use a simple NumberAnimation for perfectly linear movement
        //     property double smoothX: targetX
        //     property double smoothY: targetY
        //     property double smoothHeading: targetHeading

        //     Behavior on smoothX { NumberAnimation { duration: 150; easing.type: Easing.Linear } }
        //     Behavior on smoothY { NumberAnimation { duration: 150; easing.type: Easing.Linear } }
        //     Behavior on smoothHeading { RotationAnimation { duration: 150; direction: RotationAnimation.Shortest } }

        //     // 3. THE HEARTBEAT: This runs at 60 FPS
        //     // It constantly tells ArcGIS where the ship is RIGHT NOW during the animation
        //     Timer {
        //         id: refreshTimer
        //         interval: 16 // ~60 Frames Per Second
        //         running: true
        //         repeat: true
        //         onTriggered: {
        //             simView.mapModel.movingWatercraft(
        //                 shipManager.smoothX,
        //                 shipManager.smoothY,
        //                 shipManager.smoothHeading
        //             )
        //         }
        //     }
//}
    VesselProfileEditor {
            id: vesselEditorDialog

            onApplyVesselRequested: function(shipName, shipType,shipColor) {

                leftPanel.vesselListModel.append({ "shipName": shipName, "shipType": shipType ,"shipColor": shipColor})
                // This runs when the blue "ADD VESSEL" button in the dialog is pressed.
                // It executes your original placement logic.
                if (simView.mapModel.placingWatercraft) {
                    simView.mapModel.cancelPlacing()
                } else {
                    // You can eventually pass shipName or shipType to this C++ function
                    // if you update your C++ backend to accept them!
                    //simView.mapModel.startPlacingWatercraft("KVLCC2-01",shipColor)
                    simView.mapModel.startPlacingWatercraft(shipName, shipColor)
                }
            }
    }
    function globalCameraLockClick(viewName)
    {
        if(viewName === "Bridge View"){
            simView.mapModel.lockCamera()
            console.log("has been clicked")
        }
    }
    StatusBar {
        id: bottomStatusBar
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        z: 200 // Ensure it layers clearly over the background views
        depth: simView.currentDepth
        latitude: {
            var rawStr = simView.currentEcdisCoords
            // Safety check: if string is empty, null, or undefined, show placeholder
            if (!rawStr || typeof rawStr !== "string")
                return "00°00.000N"

            // Split by any sequence of spaces
            var parts = rawStr.trim().split(/\s+/)

            // parts[0] = "00", parts[1] = "00.000N"
            if (parts.length >= 2) {
                return parts[0] + "°" + parts[1]
            }
            return "00°00.000N"
        }

        longitude: {
            var rawStr = simView.currentEcdisCoords
            if (!rawStr || typeof rawStr !== "string")
                return "000°00.000W"

            var parts = rawStr.trim().split(/\s+/)

            // parts[2] = "000", parts[3] = "00.000W"
            if (parts.length >= 4) {
                return parts[2] + "°" + parts[3]
            }
            return "000°00.000W"
        }
        mapScale: simView.mapModel.currentMapScale
    ShipTrackingEditor {
            id: trackingEditorDialog
            onApplyTrackingRequested: function(target, duration, period, timestamp, trackColor) {
                console.log("qml: Applying Tracking Configuration -> Target:", target, "Duration:", duration, "Period:", period, "Timestamp Interval:", timestamp, "Color hex:", trackColor)
                switch(target){
                case "Plotting":
                    simView.mapModel.setPlotting(period,duration,trackColor)
                    simView.mapModel.setTimeStampDurationMinutes(timestamp)
                    break;
                case "Track":
                    simView.mapModel.setTrack(period,duration,trackColor)
                    break;
                case "Trend":
                    simView.mapModel.setTrend(period,duration,trackColor)
                    break;
                default:
                }
                // Connect parameters here directly to your custom C++ map view model hooks if applicable
                // Example: simView.mapModel.setTrackingParameters(duration, period, timestamp, trackColor)
            }
        }


    // --- ZOOM AREA KEYBOARD SHORTCUT ---
    Shortcut {
        sequence: "Ctrl+Z"
        onActivated: {
            // FIX: Use 'zoomAreaButton'
            topBar.zoomAreaButton.checked = !topBar.zoomAreaButton.checked
        }
    }
    }
}


