import QtQuick
import QtQuick.Controls

TabButton {
    id: root

    contentItem: Text {
        text: root.text
        anchors.centerIn: parent
        color: "white"
        font.pixelSize: 14
    }

    background: Rectangle {
        color: root.checked ? "#2d8cff" : "#2b2b2b"
        radius: 6
    }
}
