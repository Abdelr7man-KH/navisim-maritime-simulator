import QtQuick
import QtQuick.Controls
import Esri.display_s57_chart 1.0
import PlaceableObjects.Watercraft 1.0
Item {
    id: root
    anchors.fill: parent
    property alias mapControl: mapView
    property alias mapModel: displayChart
    property var currentEcdisCoords: null
    property var currentDepth: null
    property int currentMouseX: 0
    property int currentMouseY: 0
    Rectangle {
        anchors.fill: parent
        color: "#1e293b"

        // Text {
        //     text: "Simulation Viewport"
        //     anchors.centerIn: parent
        //     color: "#94a3b8"
        //     font.pixelSize: 28
        // }
        Display_s57_chart {
            id: displayChart
            mapView: mapView
            onRulerMeasured: function(meters, nm) {
                distanceLabel.text = nm.toFixed(2) + " NM  (" + (meters / 1000).toFixed(2) + " km)"
                resultPanel.visible = true
            }

            onWatercraftInfoReady: function(info) {
                infoText.text = info
                infoPanel.visible = true
            }

            onShowContextMenu: {
                shipContextMenu.popup()   // ← triggered from C++
            }
        }
        MapView{
            id: mapView
            anchors.fill: parent

        }
        MouseArea {
                    id: mapMouseArea
                    anchors.fill: mapView
                    hoverEnabled: true
                    z: 1

                    // Dynamic Button Acceptance: Only intercepts clicks if a layout tool is active.
                    // Otherwise, lets clicks fall through directly to MapView for seamless panning!
                    acceptedButtons: (topBar.zoomAreaButton.checked || displayChart.placingWatercraft || displayChart.replacingWatercraft || displayChart.rotatingWatercraft)
                                     ? (Qt.LeftButton | Qt.RightButton)
                                     : Qt.NoButton

                    onPressed: (mouse)=> {
                        if (mouse.button === Qt.RightButton) {
                            // Cancel active tool and consume right click
                            if (topBar.zoomAreaButton.checked) {
                                topBar.zoomAreaButton.checked = false
                                mouse.accepted = true
                            } else {
                                mouse.accepted = false
                            }
                        }
                        else if (mouse.button === Qt.LeftButton && topBar.zoomAreaButton.checked) {
                            simView.mapModel.startZoomBox(mouse.x, mouse.y)
                            mouse.accepted = true
                        }
                        else {
                            mouse.accepted = false
                        }
                    }

                    onPositionChanged: function(mouse) {
                        currentMouseX = mouse.x
                        currentMouseY = mouse.y
                        root.currentEcdisCoords = displayChart.screenToEcdisCoordinate(mouse.x, mouse.y)

                        if (displayChart.erblActive && displayChart.erblOriginSet) {
                            displayChart.updateERBLLine(mouse.x, mouse.y)
                            erblCursorBox.x = mouse.x + 12
                            erblCursorBox.y = mouse.y + 12

                            if ((erblCursorBox.x + erblCursorBox.width) > mapView.width) {
                                erblCursorBox.x = mouse.x - erblCursorBox.width - 12
                            }
                            if ((erblCursorBox.y + erblCursorBox.height) > mapView.height) {
                                erblCursorBox.y = mouse.y - erblCursorBox.height - 12
                            }
                        }

                        if (displayChart.placingWatercraft)
                            displayChart.updatePendingPreview(mouse.x, mouse.y)

                        if (displayChart.replacingWatercraft || displayChart.rotatingWatercraft)
                            displayChart.updateReplacingOrRotating(mouse.x, mouse.y)

                        // Handing Zoom Dragging safely
                        if (topBar.zoomAreaButton.checked && pressed) {
                            displayChart.updateZoomBox(mouse.x, mouse.y)
                        }

                        // DEBOUNCE FIX: Don't call identifyDepthAtScreen immediately on every pixel movement.
                        // Store the coordinate and restart the timer to throttle spatial queries.
                        depthQueryTimer.screenX = mouse.x
                        depthQueryTimer.screenY = mouse.y
                        depthQueryTimer.restart()
                    }

                    onReleased: (mouse)=> {
                        if (mouse.button === Qt.LeftButton && topBar.zoomAreaButton.checked) {
                            simView.mapModel.finishZoomBox(mouse.x, mouse.y)
                            topBar.zoomAreaButton.checked = false
                            mouse.accepted = true
                        } else {
                            mouse.accepted = false
                        }
                    }

                    Timer {
                        id: depthQueryTimer
                        interval: 50 // Throttles processing overhead to 200ms windows
                        repeat: false
                        property double screenX: 0
                        property double screenY: 0
                        // SCOPE FIX: Accesses the internal timer properties safely, not 'mouse'
                        onTriggered: displayChart.identifyDepthAtScreen(screenX, screenY)
                    }

                    Connections {
                        target: displayChart
                        function onDepthIdentified(depthText) {
                            root.currentDepth = depthText
                            displayText.text = depthText
                        }
                    }
        }

        // ── Context menu ─────────────────────────────────────────────────────────
        Menu {
            id: shipContextMenu

            MenuItem {
                text: "Replace"
                onTriggered: displayChart.startReplacingWatercraft()
            }
            MenuItem {
                text: "Rotate"
                onTriggered: displayChart.startRotatingWatercraft()
            }
            MenuSeparator {}
            MenuItem {
                text: "Rename object"
                onTriggered: {
                    renameInput.text = displayChart.selectedWatercraft
                            ? displayChart.selectedWatercraft.name : ""
                    renameDialog.open()
                }
            }
            //Test
            MenuItem {
                text: "Set primary ship"
                onTriggered: {
                    if (displayChart.selectedWatercraft)
                        displayChart.makeMainShip(displayChart.selectedWatercraft.name)
                }
            }
            MenuItem {
                text: "Delete object"
                onTriggered: {
                    if (displayChart.selectedWatercraft)
                        displayChart.selectedWatercraft.deleteObject()
                }
            }
            MenuSeparator {}
            MenuItem {
                text: "Object information"
                onTriggered: {
                    if (displayChart.selectedWatercraft)
                    {
                        displayChart.selectedWatercraftInfo()
                        console.log(displayChart.primaryShip.currentLocation)
                    }

                }
            }
        }

        // ── Rename dialog ────────────────────────────────────────────────────────
        Dialog {
            id: renameDialog
            title: "Rename Object"
            anchors.centerIn: parent
            standardButtons: Dialog.Ok | Dialog.Cancel

            TextField {
                id: renameInput
                placeholderText: "Enter new name"
                width: 200
            }

            onAccepted: {
                if (displayChart.selectedWatercraft)
                    displayChart.selectedWatercraft.name = renameInput.text
            }
        }

        // ── Info panel ───────────────────────────────────────────────────────────
        Rectangle {
            id: infoPanel
            visible: false
            anchors { top: parent.top; left: parent.left; margins: 10 }
            width: 220
            height: infoText.implicitHeight + 20
            radius: 8
            color: "#CC000000"
            border.color: "#446688"
            border.width: 1
            z: 2

            Text {
                id: infoText
                anchors { fill: parent; margins: 10 }
                color: "white"
                font.family: "Courier New"
                font.pixelSize: 12
            }

            MouseArea {
                anchors.fill: parent
                onClicked: infoPanel.visible = false
            }
        }

        // ── Coordinate display ───────────────────────────────────────────────────
        Rectangle {
            id: coordDisplay
            anchors {
                bottom: mapView.bottom
                bottomMargin: 40
                left: mapView.left
                leftMargin: 50
            }
            width: 240
            height: 36
            radius: 6
            color: "#CC000000"
            border.color: "#446688"
            border.width: 1
            z: 1

            property real lat: 0
            property real lon: 0
            Text {
                id: displayText
                anchors.centerIn: parent
                text: "Lat: " + coordDisplay.lat.toFixed(6) + "   Lon: " + coordDisplay.lon.toFixed(6) + "Depth :"
                color: "white"
                font.pixelSize: 12
                font.family: "Courier New"
            }
        }
        Rectangle {
            id: resultPanel
            visible: false
            anchors {
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
                bottomMargin: 20
            }
            width: 280
            height: 44
            radius: 8
            color: "#CC000000"
            z: 1

            Text {
                id: distanceLabel
                anchors.centerIn: parent
                color: "white"
                font.pixelSize: 16
            }

            MouseArea {
                anchors.fill: parent
                onClicked: resultPanel.visible = false
            }
        }
        Connections {
            target: displayChart
            function onEncLoadSuccess() {
                loadStatusLabel.text = "✅ Chart loaded successfully"
                loadStatusLabel.visible = true
            }

            function onEncLoadFailed(message) {
                loadStatusLabel.text = "❌ " + message
                loadStatusLabel.visible = true
            }
        }

        Text {
            id: loadStatusLabel
            visible: false
            color: "white"
            font.pixelSize: 13
            anchors {
                bottom: parent.bottom
                horizontalCenter: parent.horizontalCenter
                bottomMargin: 70
            }

            // Auto hide after 3 seconds
            onVisibleChanged: {
                if (visible) hideTimer.restart()
            }

            Timer {
                id: hideTimer
                interval: 3000
                onTriggered: loadStatusLabel.visible = false
            }
        }
        Rectangle {
            id: erblCursorBox
            // Only visible when ERBL is actively measuring across the chart
            width: 85
            height: 34
            border.color: "#FFA500" // Orange border matching the ERBL line
            border.width: 1
            radius: 3
            z: 9999                 // Keep it on top of all chart vectors

            Column {
                anchors.centerIn: parent
                spacing: 1

                Text {
                    id: erblBearing
                    // Pulls the current bearing string directly from your panel data
                    text: "--"
                    color: "#FFA500"
                    font.pixelSize: 10
                    font.bold: true
                    font.family: "Courier New"
                }
                Text {
                    id: erblRange
                    // Pulls the NM range string directly (splits out any meters/km text)
                    text: "--"
                    color: "#FFA500"
                    font.pixelSize: 10
                    font.bold: true
                    font.family: "Courier New"
                }
            }
        }
        Connections {
            target: displayChart
            function onErblUpdated(rangeNM, rangeMeters, bearingDeg) {
                erblCursorBox.visible  = true
                erblBearing.text   = bearingDeg.toFixed(1) + "°"
                erblRange.text     = rangeNM.toFixed(2) + " NM\n" +
                        (rangeMeters < 1000
                         ? rangeMeters.toFixed(0) + " m"
                         : (rangeMeters/1000).toFixed(2) + " km")
            }
            function onErblCleared() {
                erblCursorBox.visible = false
            }
        }
    }
}

/*

        MouseArea {
            anchors.fill: mapView
            hoverEnabled: true
            acceptedButtons: Qt.NoButton   // ← key: never consumes clicks
            z: 1
            onReleased: (mouse)=> {

                            if (mouse.button === Qt.LeftButton && topBar.zoomAreaButton.checked) {
                                // Finish drawing and execute the zoom!

                                simView.mapModel.finishZoomBox(mouse.x, mouse.y)
                                // Optional: Uncheck the button automatically after zooming once
                                topBar.zoomAreaButton.checked = false
                            } else {
                                mouse.accepted = false
                            }
                        }
            onPressed: (mouse)=> {
                           if (mouse.button === Qt.RightButton) {
                               // 1. If a tool is active, cancel it and consume the click
                               if (topBar.zoomAreaButton.checked) {
                                   topBar.zoomAreaButton.checked = false
                                   mouse.accepted = true
                               } else {
                                   // 2. CRITICAL: If no tools are active, let the right-click pass
                                   // through to the C++ map so it can trigger the Context Menu!
                                   mouse.accepted = false
                               }
                           }
                           else if (mouse.button === Qt.LeftButton && topBar.zoomAreaButton.checked) {
                               // Start drawing the zoom box
                               simView.mapModel.startZoomBox(mouse.x, mouse.y)
                               mouse.accepted = true
                           }
                           else {
                               // Let standard map panning and left-click vessel selection work
                               mouse.accepted = false
                           }
                       }
            onPositionChanged: function(mouse) {
                currentMouseX = mouse.x
                currentMouseY = mouse.y
                root.currentEcdisCoords = displayChart.screenToEcdisCoordinate(mouse.x, mouse.y)
                if (displayChart.erblActive && displayChart.erblOriginSet) {
                    displayChart.updateERBLLine(mouse.x, mouse.y)
                    // ── Track Cursor Position ───────────────────────────────────────
                    erblCursorBox.x = mouse.x + 12
                    erblCursorBox.y = mouse.y + 12
                    // Screen boundary guard: keeps the small box from sliding off screen edges

                    if ((erblCursorBox.x + erblCursorBox.width) > mapView.width) {
                        erblCursorBox.x = mouse.x - erblCursorBox.width - 12
                    }
                    if ((erblCursorBox.y + erblCursorBox.height) > mapView.height) {
                        erblCursorBox.y = mouse.y - erblCursorBox.height - 12
                    }
                }
                if (displayChart.placingWatercraft)
                    displayChart.updatePendingPreview(mouse.x, mouse.y)
                if (displayChart.replacingWatercraft || displayChart.rotatingWatercraft)
                    displayChart.updateReplacingOrRotating(mouse.x, mouse.y)
                // ZoomArea Button
                if (topBar.zoomAreaButton.checked && pressed) {
                    // Update the rectangle as you drag
                    displayChart.updateZoomBox(mouse.x, mouse.y)
                } else {
                    mouse.accepted = false
                }
                displayChart.identifyDepthAtScreen(mouse.x,mouse.y)
            }
            Timer {
                id: depthQueryTimer
                interval: 300
                repeat: false
                property double screenX: 0
                property double screenY: 0
                onTriggered: displayChart.identifyDepthAtScreen(mouse.x,mouse.y)
            }
            Connections {
                target: displayChart
                function onDepthIdentified(depthText) {
                    root.currentDepth = depthText
                    displayText.text = depthText
                }
            }

}*/
