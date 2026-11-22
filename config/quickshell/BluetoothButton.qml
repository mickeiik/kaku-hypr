import QtQuick

BarButton {
    panel: "bluetooth"
    icon: ""
    iconFamily: "Font Awesome 7 Brands"
    iconColor: !BluetoothService.on ? Theme.muted : BluetoothService.connectedCount > 0 ? Theme.accent : Theme.fg
    text: BluetoothService.connectedCount > 1 ? BluetoothService.connectedCount : ""
}
