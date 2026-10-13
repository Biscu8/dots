import Quickshell
import Quickshell.Io
import QtQuick

pragma ComponentBehavior: Bound

Scope {
	id: root

	Variants {
		model: Quickshell.screens
		PanelWindow {
			id: panel
			required property var modelData
			property int fontSize: 14
			property string backgroundColor: "#505050"
			property string hoveredBackgroundColor: "#404040"
			property string textColor: "#ffffff"
			screen: modelData
			color: "#505050"
			anchors {
				top: true
				left: true
				right: true
			}

			implicitHeight: 35
			Object {
				id: clock
				anchors.centerIn: parent
				normalColor: panel.backgroundColor
				hoveredColor: panel.backgroundColor
				textColor: panel.textColor
				fontPointSize: panel.fontSize
				padding: 6
				height: 26
				
				update: function fun(hovered) {
					if (hovered) {
						return Time.dateTime
					} else {
						return Time.time
					}
				}
			}
			Object {
				id: battery
				anchors.verticalCenter: parent.verticalCenter
				anchors.right: parent.right
				anchors.left: undefined
				normalColor: panel.backgroundColor
				hoveredColor: panel.backgroundColor
				textColor: panel.textColor
				fontPointSize: panel.fontSize
				padding: 6
				height: 26
				property string acOnline
				property string batPercent
				
				Process {
					id: acOnlineProc
					command: ["cat", "/sys/class/power_supply/AC/online"]
					running: true
					stdout: StdioCollector {
						onStreamFinished: battery.acOnline = this.text.trim()
					}
				}
				Process {
					id: batProc
					command: ["cat", "/sys/class/power_supply/BAT0/capacity"]
					running: true
					stdout: StdioCollector {
						onStreamFinished: battery.batPercent = this.text.trim()
					}
				}
				Timer {
					interval: 60000
					running: true
					repeat: true
					onTriggered: {
						batProc.running = true
						acOnlineProc.running = true
					} 
				}
				update: function fun(hovered) {
					if (root.acOnline == "1") {
						if (hovered) {
							return batPercent + " %"
						} else {
							return batPercent + " %"
						}
					} else {
						if (hovered) {
							return batPercent + " %"
						} else {
							return batPercent + " %"
						}
					}
				}
			}
		}
	}
}
