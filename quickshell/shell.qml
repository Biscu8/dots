import Quickshell
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

import "./wallpaper"


PanelWindow {
    id: root

    aboveWindows: true
    visible: false

    anchors {
        top: true
        right: true
    }

    implicitWidth: 300
    implicitHeight: 44

    color: "transparent"

    // --------------------------------------------------
    // Status state
    // --------------------------------------------------

    property string statusText: ""

    function showStatus(message) {
        statusText = message
        visible = true
        hideTimer.restart()
	}

	function showUrgent(message) {
		statusText = message;
		visible = true;
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

        const drop = batteryReference - current

        // Notify after every 10 percentage points lost.
		if (drop >= 10) {
			if (current <= 20) {
				showUrgent("Battery low · " + current + " %");
			} else {
				showStatus("Battery -" + drop + " % · " + current + " %")
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
				root.showStatus("Brightness · " + text[3]);
			}
		}
	}

	IpcHandler {
		target: "status"

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
