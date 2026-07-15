// MapController.qml
import QtQuick

Item {
    id: controller

    // Linked to simView.mapModel in main.qml
    property var targetMapModel: null

    function zoomIn() {
        if (targetMapModel) {
            console.log("MapController: Executing Zoom In...");
            targetMapModel.zoomIn();
        } else {
            console.warn("MapController Error: targetMapModel is null! Check your main.qml binding.");
        }
    }

    function zoomOut() {
        if (targetMapModel) {
            console.log("MapController: Executing Zoom Out...");
            targetMapModel.zoomOut();
        } else {
            console.warn("MapController Error: targetMapModel is null!");
        }
    }

    // --- CHART CENTERING SHORTCUTS ---

    // Toggle Centering Mode
    Shortcut {
        sequence: "Ctrl+Alt+C"
        onActivated: {
            if (targetMapModel) {
                // Toggle the C++ property directly
                targetMapModel.centerModeActive = !targetMapModel.centerModeActive
            }
        }
    }

    // Shift + Arrows for directional panning (Only active when centering mode is on)
    Shortcut {
        sequence: "Shift+Left"
        onActivated: {
            if (targetMapModel && targetMapModel.centerModeActive) {
                targetMapModel.panMapCenter(-1, 0)
            }
        }
    }

    Shortcut {
        sequence: "Shift+Right"
        onActivated: {
            if (targetMapModel && targetMapModel.centerModeActive) {
                targetMapModel.panMapCenter(1, 0)
            }
        }
    }

    Shortcut {
        sequence: "Shift+Up"
        onActivated: {
            if (targetMapModel && targetMapModel.centerModeActive) {
                // Screen coordinates: 0 is top, so UP is a negative Y shift
                targetMapModel.panMapCenter(0, -1)
            }
        }
    }

    Shortcut {
        sequence: "Shift+Down"
        onActivated: {
            if (targetMapModel && targetMapModel.centerModeActive) {
                // Screen coordinates: DOWN is a positive Y shift
                targetMapModel.panMapCenter(0, 1)
            }
        }
    }
}
