import QtQuick

Rectangle {
	id: root
	property int fontPointSize: 14
	property string textColor: "#ffffff"
	property string normalColor: "#bbbbbb"
	property string hoveredColor: "#444444"
	property int padding: 2
	property var update
	color: mouse.hovered ? hoveredColor : normalColor
	width: text.implicitWidth + padding * 2
	height: text.implicitHeight + padding * 2
	Text {
		id: text
		font.pointSize: root.fontPointSize
		color: root.textColor
		anchors.centerIn: root
		HoverHandler {
			id: mouse
			acceptedDevices: PointerDevice.TouchPad | PointerDevice.Mouse
		}
		text: root.update(mouse.hovered)
	}
}
