import QtQuick
import QtQuick.Layouts

Rectangle {
    id: statusRoot
    height: 30
    color: "#f1f5f9" // Light pro-application gray background
    border.color: "#cbd5e1"
    border.width: 1

    // --- PUBLIC PROPERTIES (Drive these from main.qml) ---
    property string depth: "0"
    property real windSpeed: 0.0
    property real windDirection: 0.0
    property real currentSpeed: 0.0
    property real currentDirection: 0.0
    property string latitude: "50°33.144N"
    property string longitude: "009°46.154W"
    property int mapScale: 30000
    property string timeText: Qt.formatDateTime(new Date(), "HH:mm:ss")
    Timer {
        interval: 1000 // 1000 milliseconds = 1 second
        running: true // Start automatically
        repeat: true // Keep running indefinitely

        onTriggered: {
            statusRoot.timeText = Qt.formatDateTime(new Date(), "HH:mm:ss")
        }
    }
    RowLayout {
        anchors.fill: parent
        spacing: 0

        // 1. Depth
        StatusField {
            text: "Depth: " + statusRoot.depth
            fieldWidth: 100
        }

        StatusDivider {}

        // 2. Wind
        StatusField {
            text: "Wind " + statusRoot.windSpeed.toFixed(
                      1) + " m/s " + statusRoot.windDirection.toFixed(
                      1).padStart(5, '0') + "°"
            fieldWidth: 150
        }

        StatusDivider {}

        // 3. Current
        StatusField {
            text: "Current " + statusRoot.currentSpeed.toFixed(
                      1) + " m/s " + statusRoot.currentDirection.toFixed(
                      1).padStart(5, '0') + "°"
            fieldWidth: 150
        }

        StatusDivider {}

        // 6. Latitude
        StatusField {
            text: statusRoot.latitude
            fieldWidth: 110
        }

        StatusDivider {}

        // 7. Longitude
        StatusField {
            text: statusRoot.longitude
            fieldWidth: 110
        }

        StatusDivider {}

        // 8. Scale Panel
        StatusField {
            text: "1 : " + statusRoot.mapScale.toLocaleString(Qt.locale(), 'f',
                                                              0)
            fieldWidth: 100
        }

        StatusDivider {}

        // 10. Time Panel (Fills remaining space tightly or pushes right)
        StatusField {
            text: statusRoot.timeText
            Layout.fillWidth: true
            alignment: Qt.AlignLeft
        }
    }

    // --- INTERNAL REUSABLE ITEMS ---
    component StatusField: Item {
        id: fieldRoot
        property string text: ""
        property int alignment: Text.AlignHCenter
        property real fieldWidth: 120
        property bool fillRemainingSpace: false

        Layout.fillHeight: true
        Layout.fillWidth: fieldRoot.fillRemainingSpace
        Layout.preferredWidth: fieldRoot.fillRemainingSpace ? -1 : fieldRoot.fieldWidth

        Text {
            id: contentText
            text: fieldRoot.text
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: fieldRoot.alignment
            color: "#334155"
            font.pixelSize: 11
            font.family: "Consolas, Monaco, Courier New, Arial"
        }
    }

    component StatusDivider: Rectangle {
        width: 1
        Layout.fillHeight: true
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        color: "#cbd5e1"
    }
}
