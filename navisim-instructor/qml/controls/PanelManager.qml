import QtQuick

QtObject {
    id: manager

    // State properties
    property bool leftOpen: false
    property bool rightOpen: false

    // Section tracking
    property string leftSection: "environment"
    property string rightSection: "monitoring"

    // Logic for the Left Panel (Environment, Incidents, etc.)
    function openLeft(sectionName) {
        if (leftOpen && leftSection === sectionName) {
            leftOpen = false; // Toggle off
        } else {
            leftSection = sectionName;
            leftOpen = true;
        }
    }

    // Logic for the Right Panel (Monitoring, Log, Chat)
    function openRight(sectionName) {
        if (rightOpen && rightSection === sectionName) {
            // Only close if we click the EXACT same icon/tab again
            rightOpen = false;
        } else {
            // If it was closed, open it. If it was open on a different tab, just switch.
            rightSection = sectionName;
            rightOpen = true;
        }
    }

    function closePanels() {
        leftOpen = false;
        rightOpen = false;
    }
}
