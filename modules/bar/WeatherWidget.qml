import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import "root:/scripts"
import QtQuick.Layouts
import Quickshell;
import Quickshell.Io;
import Qt.labs.platform
import QtQuick;

Item {
    id: root
    property bool borderless: ConfigOptions.bar.borderless
    implicitWidth: rowLayout.implicitWidth

    RowLayout {
        id: rowLayout
        anchors.centerIn: parent
        spacing: 4

        MaterialSymbol {
            fill: 1
            text: "device_thermostat"
            iconSize: Appearance.font.pixelSize.normal
            color: Appearance.m3colors.m3onSecondaryContainer
        }

        StyledText {
            id: weather
            font.pixelSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnLayer1
            Process {
                command: ['../../scripts/weather.sh']
                running: true
                stdout: StdioCollector {
                    // Listen for the streamFinished signal, which is sent
                    // when the process closes stdout or exits.
                    onStreamFinished: (_) => {
                        const parsedWeather = JSON.parse(this.text)

                        weather.text = parsedWeather.current_condition[0].weatherCode
                    }
                }
                stderr: StdioCollector {
                    onStreamFinished: weather.text = "AHHH"
                }
            }
        }
    }
    
}