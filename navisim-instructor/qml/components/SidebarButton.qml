import QtQuick
import QtQuick.Controls

Item {
    id: control
    width: 40
    height: 40

    property string iconPath: ""
    property string iconText: ""
    property string toolTipText: ""

    signal clicked()

    // Background
    Rectangle {
        anchors.fill: parent
        color: mouseArea.containsMouse ? "#f1f5f9" : "transparent"
        radius: 8
    }

    // SVG icon
    Image {
        visible: control.iconPath !== ""
        source: control.iconPath
        anchors.centerIn: parent
        width: 24
        height: 24
        sourceSize.width: 24
        sourceSize.height: 24
        fillMode: Image.PreserveAspectFit
    }

    // Emoji fallback
    Text {
        visible: control.iconPath === ""
        text: control.iconText
        anchors.centerIn: parent
        font.pixelSize: 20
        color: "#1e293b"
    }

    // Tooltip
    ToolTip {
        visible: mouseArea.containsMouse && control.toolTipText !== ""
        delay: 300
        text: control.toolTipText
    }

    // Mouse handler
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: control.clicked()
    }
}
