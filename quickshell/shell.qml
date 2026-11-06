import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import Quickshell.Services.UPower
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

import "./wallpaper"

ShellRoot {
	PanelWindow {
		id: root

		aboveWindows: true
		visible: false

		anchors {
			top: true
			right: true
		}

		implicitWidth: 384
		implicitHeight: 64

		color: "transparent"

		// --------------------------------------------------
		// Status state
		// --------------------------------------------------

		property string statusText: ""

		function showStatus(message) {
			statusText = message
			visible = true & !status.visible;
			hideTimer.restart()
		}

		function showUrgent(message) {
			statusText = message;
			visible = true & !status.visible;
			hideTimer.interval = 12000;
			text.color = "#F3FAF289";
			text.font.family = "IBM Plex Sans Bold";
			hideTimer.restart();
		}

		Timer {
			id: hideTimer
			interval: 6000
			repeat: false

			onTriggered: {
				root.visible = false;
				text.color = "#F3EBEEF3";
				text.font.family = "IBM Plex Sans";
				interval = 6000;
			}
		}

		// --------------------------------------------------
		// Battery
		// --------------------------------------------------

		property int batteryReference: -1

		function updateBattery() {
			const battery = UPower.displayDevice

			if (!battery.ready)
				return

			const current = Math.round(battery.percentage * 100)

			// First reading establishes the baseline.
			if (batteryReference < 0) {
				batteryReference = current
				return
			}

			// While charging, continuously update the baseline.
			if (!UPower.onBattery) {
				batteryReference = current
				return
			}

			// Notify after every 10 percentage points lost.
			if (current % 10 === 0) {
				if (status.visible) {
					statusBat.text = "Battery · " + current + " %";
				} else if (current <= 20) {
					showUrgent("Battery low · " + current + " %");
				} else {
					showStatus("Battery · " + current + " %")
				}
				batteryReference = current
			}
		}

		Connections {
			target: UPower.displayDevice

			function onReadyChanged() {
				root.updateBattery()
			}

			function onPercentageChanged() {
				root.updateBattery()
			}
		}

		Connections {
			target: UPower

			function onOnBatteryChanged() {
				root.batteryReference = -1
				root.updateBattery()

				root.showStatus(
					UPower.onBattery ? "Running on battery" : "Power connected"
				)
			}
		}


		// Network
		//

		property var wifiDevice: {
			const devices = Networking.devices.values;

			for (let i = 0; i < devices.length; i++) {
				if (devices[i].type === DeviceType.Wifi)
				return devices[i];
			}

			return null;
		}

		function updateNetwork() {
			const device = root.wifiDevice;

			if (device === null || !device.connected)
			return "No networks";

			const networks = device.networks.values;

			for (let i = 0; i < networks.length; i++) {
				const network = networks[i];

				if (network.connected) {
					return network.name + " · "
					+ Math.round(network.signalStrength * 100) + " %";
				}
			}

			return "No networks";
		}

		function refreshNetwork() {
			root.showStatus(root.updateNetwork());
		}

		// Listen for Wi-Fi connection/disconnection.
		Connections {
			target: root.wifiDevice

			function onConnectedChanged() {
				root.refreshNetwork();
			}
		}

		// Initial status
		Component.onCompleted: root.refreshNetwork()

		// --------------------------------------------------
		// Audio
		// --------------------------------------------------

		property var audioSink: Pipewire.defaultAudioSink

		property real lastVolume: -1
		property var lastMuted: null

		PwObjectTracker {
			objects: [root.audioSink]
		}

		function syncAudioBaseline() {
			if (!audioSink || !audioSink.ready || !audioSink.audio)
				return

			lastVolume = audioSink.audio.volume
			lastMuted = audioSink.audio.muted
		}

		onAudioSinkChanged: {
			lastVolume = -1
			lastMuted = null
			syncAudioBaseline()
		}

		Connections {
			target: root.audioSink

			function onReadyChanged() {
				root.syncAudioBaseline()
			}
		}

		Connections {
			target: root.audioSink ? root.audioSink.audio : null

			function onVolumeChanged() {
				if (!root.audioSink || !root.audioSink.ready)
					return

				const current = root.audioSink.audio.volume

				// Avoid notifying on initial synchronization.
				if (root.lastVolume < 0) {
					root.lastVolume = current
					return
				}

				const previous = root.lastVolume
				root.lastVolume = current

				if (Math.abs(current - previous) < 0.005)
					return

				const direction = current > previous
					? "increased"
					: "decreased"

				root.showStatus(
					"Volume " + direction + " · " +
					Math.round(current * 100) + "%"
				)
			}

			function onMutedChanged() {
				if (!root.audioSink || !root.audioSink.ready)
					return

				const muted = root.audioSink.audio.muted

				if (root.lastMuted === null) {
					root.lastMuted = muted
					return
				}

				if (muted === root.lastMuted)
					return

				root.lastMuted = muted

				root.showStatus(muted ? "Audio muted" : "Audio unmuted")
			}
		}

		// --------------------------------------------------
		// Brightness
		// --------------------------------------------------
		Process {
			id: brightnessProcess
			running: false
			// command: [ "sh", "-c", "brightnessctl -m" ]
			command: [ "/usr/bin/brightnessctl", "-m" ]
			stdout: StdioCollector {
				onStreamFinished: {
					const text = this.text.split(",");
					if (status.visible) {
						display.text = "Brightness · " + text[3];
					} else {
						root.showStatus("Brightness · " + text[3]);
					}
				}
			}
		}

		IpcHandler {
			target: "brightness"

			function brightnessChanged(): void {
				brightnessProcess.running = true;
			}
		}

		// --------------------------------------------------
		// Time
		// --------------------------------------------------

		SystemClock {
			id: clock

			precision: SystemClock.Minutes

			onMinutesChanged: {
				if (clock.minutes % 15 === 0) {
					root.showStatus(
						"Time · " + Qt.formatDateTime(clock.date, "hh:mm")
					)
				}
			}
		}

		// --------------------------------------------------
		// Visuals
		// --------------------------------------------------

		Wallpaper { }

		Rectangle {
			id: widget

			anchors.fill: parent
			anchors.margins: 8

			color: "#F3191C23"
			border.color: "#636C7D"
			border.width: 2
			radius: 8

			Text {
				id: text
				anchors.centerIn: parent

				width: parent.width - 24

				horizontalAlignment: Text.AlignHCenter
				verticalAlignment: Text.AlignVCenter

				color: "#F3EBEEF3"
				text: root.statusText
				font.pixelSize: 14
				font.family: "IBM Plex Sans"

				elide: Text.ElideRight
			}
		}

		// The panel is passive: clicks pass through its visible area.
		mask: Region {
			item: widget
			intersection: Intersection.Xor
		}
	}

	IpcHandler {
		target: "lock"

		function toggle(): void {
			lock.locked = !lock.locked;
		}
		function showLock(): void {
			lock.locked = true;
		}
	}

	WlSessionLock {
		id: lock
		locked: true
		surface: Component {
			WlSessionLockSurface {
				Image {
					id: wallpaper
					anchors.fill: parent
					source: "/home/Biscu1ts/Wallpapers/ina3.jpg"
					fillMode: Image.PreserveAspectCrop
					width: 1920
					height: 1200
					asynchronous: true
					mipmap: true
				}

				Rectangle {
					id: rec
					anchors.centerIn: parent
					property int padding: 64
					width: col.width + padding
					height: col.height + padding
					color: "#F3191C23"
					border.color: "#636C7D"
					border.width: 2
					radius: 8
					Column {
						id: col
						anchors.centerIn: parent
						spacing: 16
						Text {
							text: {
								const day = parseInt(Qt.formatDateTime(clock.date, "d"));
								let str = "";
								switch(day) {
									case 1: str = "st";
									break;
									case 2: str = "nd";
									break;
									case 3: str = "rd";
									break;
									default: str = "th"; 
								}
								const month = Qt.formatDateTime(clock.date, "dddd, MMMM ");
								const year = Qt.formatDateTime(clock.date, " yyyy");
								return month + day + str + year;
							}
							anchors.horizontalCenter: parent.horizontalCenter
							font.pointSize: 40
							font.family: "IBM Plex Sans"
							color: "#F3EBEEF3"
						}
						Text {
							text: Qt.formatDateTime(clock.date, "hh:mm")
							anchors.horizontalCenter: parent.horizontalCenter
							font.pointSize: 80
							color: "#F3EBEEF3"
							height: contentHeight + 16
						}
						Rectangle {
							anchors.horizontalCenter: parent.horizontalCenter
							width: 384
							height: 64
							border.color: "#636C7D"
							border.width: 2
							radius: 8
							color: "#F3242836"
							TextInput {
								id: password
								anchors.centerIn: parent
								echoMode: TextInput.Password
								color: "#F3EBEEF3"
								// width: 384 - 8
								font.pointSize: 24
								clip: true
								focus: true
								onAccepted: {
									authStatus.text = "";
									if (!pam.start()) {
										authStatus.text = "Could not start authentication";
									}
								}
							}
						}
					}
					Text {
						id: authStatus
						text: ""
						anchors.horizontalCenter: parent.horizontalCenter
						font.pointSize: 18
						color: "#F3FAF289"
						height: contentHeight + 16
					}
				}
				PamContext {
					id: pam
					config: "quickshell"

					onPamMessage: {
						if (responseRequired) {
							respond(password.text);
							password.text = "";
						}
					}

					onCompleted: result => {
						if (result === PamResult.Success) {
							lock.locked = false;
						} else {
							authStatus.text = "Authentication failed";
							password.text = "";
							password.forceActiveFocus();
						}
					}
				}
			}
		}
	}

	IpcHandler {
		target: "status"
		function toggle() {
			status.visible = !status.visible;
			root.visible = false;
		}
	}
	PanelWindow {
		id: status
		visible: false
		color: "transparent"

		implicitWidth: content.implicitWidth + 64
		implicitHeight: content.implicitHeight + 32
		onVisibleChanged: {
			if (visible) {
				brightnessProcess.running = true;
				root.updateBattery();
			}
		}

		anchors {
			top: true
			right: true
		}

		Rectangle {
			anchors.fill: parent
			anchors.margins: 8

			color: "#F3191C23"
			border.color: "#636C7D"
			border.width: 2
			radius: 8
			ColumnLayout {
				id: content
				anchors.centerIn: parent
				spacing: 8
				// time
				Text {
					Layout.alignment: Qt.AlignHCenter
					text: Qt.formatDateTime(clock.date, "hh:mm")
					color: "#F3EBEEF3"
					font.pointSize: 40
				}
				// date
				Text {
					Layout.alignment: Qt.AlignHCenter
					text: {
						const day = parseInt(Qt.formatDateTime(clock.date, "d"));
						let str = "";
						switch(day) {
							case 1: str = "st";
							break;
							case 2: str = "nd";
							break;
							case 3: str = "rd";
							break;
							default: str = "th"; 
						}
						const month = Qt.formatDateTime(clock.date, "dddd, MMMM ");
						const year = Qt.formatDateTime(clock.date, " yyyy");
						return month + day + str + year;
					}
					font.pointSize: 20
					color: "#F3EBEEF3"
				}
				// cal
				// battery
				Text {
					id: statusBat
					Layout.alignment: Qt.AlignHCenter
					text: "Battery · " + Math.round(UPower.displayDevice.percentage * 100) + " %"
					font.pointSize: 20
					color: "#F3EBEEF3"
				}
				// network
				Text {
					id: net
					property var netw
					Layout.alignment: Qt.AlignHCenter
					text: {
						if (Networking.devices === null || Networking.devices === undefined) {
							return "No networks";
						}
						for (let i = 0; i < Networking.devices.values.length; i++) {
							const device = Networking.devices.values[i];
							if (device.connected) {
								for (let j = 0; j < device.networks.values.length; j++) {
									netw = device.networks.values[j];
									if (netw === undefined || netw === null) {
										continue
									}
									if (netw.connected) {
										return netw.name + " · " + Math.round(netw.signalStrength * 100) + " %";
									}
								}
							}
						}
						return "No networks";
					}
					font.pointSize: 20
					color: "#F3EBEEF3"
				}
				// display
				Text {
					id: display
					Layout.alignment: Qt.AlignHCenter
					text: "Brightness · 0%";
					font.pointSize: 20
					color: "#F3EBEEF3"
				}
				// sound
				// bluetooth
			}
		}
	}
}
