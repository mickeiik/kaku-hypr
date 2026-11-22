import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

RowLayout {
    id: root
    required property string screenName

    spacing: 0

    Repeater {
        model: Hyprland.workspaces

        Rectangle {
            id: ws
            required property HyprlandWorkspace modelData

            visible: modelData.id > 0 && modelData.monitor?.name === root.screenName // not special ones (scratchpad)
            implicitWidth: Math.max(36, label.implicitWidth + 20)
            implicitHeight: Theme.barHeight
            color: mouse.containsMouse ? Theme.bgAlt : "transparent"

            Label {
                id: label
                anchors.centerIn: parent
                text: ws.modelData.name
                color: ws.modelData.urgent ? Theme.red : ws.modelData.focused ? Theme.accent : Theme.muted
                font.bold: ws.modelData.focused
            }

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: ws.modelData.focused ? parent.width - 12 : 0
                height: 2
                color: Theme.accent
                Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                // Hyprland 0.57's dispatch takes Lua (Quickshell 0.2.1's activate() sends the old form)
                onClicked: Quickshell.execDetached(["hyprctl", "dispatch", `hl.dsp.focus({ workspace = "${ws.modelData.id}" })`])
            }
        }
    }
}
