import QtQuick
import Quickshell
import Quickshell.Wayland

// The wallpaper, behind everything on one screen (~/Pictures/Wallpapers/tokyo-night.png,
// filling the screen; the background color shows while it loads or if it's missing)
PanelWindow {
    id: root

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "qs-wallpaper"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    color: Theme.bg

    Image {
        anchors.fill: parent
        source: "file://" + Quickshell.env("HOME") + "/Pictures/Wallpapers/tokyo-night.png"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        // Decoded at the screen's size, not the picture's
        sourceSize: Qt.size(root.width * (root.screen?.devicePixelRatio ?? 1), root.height * (root.screen?.devicePixelRatio ?? 1))
    }
}
