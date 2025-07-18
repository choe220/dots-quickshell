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
    property string currentCity: ConfigOptions.bar.weather.city
    property string weatherTemp: ""
    property string feelsLikeTemp: ""
    property string weatherIcon: ""
    property string tempPreference: ConfigOptions.bar.weather.tempPreference
    property bool isLoading: true
    
    implicitWidth: rowLayout.implicitWidth
    
    // Timer to refresh weather data every 30 minutes
    Timer {
        id: refreshTimer
        interval: 30 * 60 * 1000 // 30 minutes in milliseconds
        running: true
        repeat: true
        onTriggered: fetchLocationAndWeather()
    }
    
    Component.onCompleted: {
        fetchLocationAndWeather()
    }
    
    function fetchLocationAndWeather() {
        isLoading = true
        if (currentCity === "") {
            fetchLocation()
        } else {
            fetchWeather(currentCity)
        }
    }
    
    function fetchLocation() {
        const locationProcess = Qt.createQmlObject(`
            import Quickshell.Io;
            Process {
                id: locationProc
                command: ["curl", "-s", "https://ipinfo.io/json"]
                running: true
                
                property var stdoutCollector: StdioCollector {
                    onStreamFinished: function() {
                        console.log("Location response:", this.text)
                        try {
                            const locationData = JSON.parse(this.text)
                            if (locationData && locationData.city) {
                                console.log("Got city:", locationData.city)
                                root.currentCity = locationData.city
                                root.fetchWeather(locationData.city)
                            } else {
                                console.log("No city in location data, using IP-based location")
                                root.fetchWeather("") // Will use IP-based location
                            }
                        } catch (e) {
                            console.log("Error parsing location data:", e, "Raw text:", this.text)
                            root.fetchWeather("") // Fallback
                        }
                        locationProc.destroy()
                    }
                }
                
                property var stderrCollector: StdioCollector {
                    onStreamFinished: function() {
                        // Only show error if we haven't already successfully processed stdout
                        if (root.isLoading) {
                            console.log("Location fetch error:", this.text)
                            root.fetchWeather("") // Fallback to IP-based
                        }
                        locationProc.destroy()
                    }
                }
                
                stdout: stdoutCollector
                stderr: stderrCollector
            }
        `, root)
    }
    
    function fetchWeather(city) {
        const weatherUrl = city ? 
            `https://wttr.in/${encodeURIComponent(city)}?format=j1` :
            "https://wttr.in/?format=j1"
            
        const weatherProcess = Qt.createQmlObject(`
            import Quickshell.Io;
            Process {
                id: weatherProc
                command: ["curl", "-s", "${weatherUrl}"]
                running: true
                
                property var stdoutCollector: StdioCollector {
                    onStreamFinished: function() {
                        console.log("Weather response:", this.text)
                        try {
                            const weatherData = JSON.parse(this.text)
                            console.log("Parsed weather data:", JSON.stringify(weatherData))
                            if (weatherData && weatherData.current_condition && weatherData.current_condition.length > 0) {
                                const current = weatherData.current_condition[0]
                                console.log("Current condition:", JSON.stringify(current))
                                root.weatherTemp = current.temp_${root.tempPreference} + "°${root.tempPreference}"
                                root.feelsLikeTemp = current.FeelsLike${root.tempPreference} + "°${root.tempPreference}"
                                root.weatherIcon = getWeatherIcon(current.weatherCode)
                                root.isLoading = false
                                console.log("Weather updated successfully")
                            } else {
                                console.log("Invalid weather data structure")
                                root.weatherTemp = "N/A"
                                root.feelsLikeTemp = "N/A"
                                root.weatherIcon = "cloud_off"
                                root.isLoading = false
                            }
                        } catch (e) {
                            console.log("Error parsing weather data:", e, "Raw text:", this.text)
                            root.weatherTemp = "Parse Error"
                            root.feelsLikeTemp = "Parse Error"
                            root.weatherIcon = "cloud_off"
                            root.isLoading = false
                        }
                        weatherProc.destroy()
                    }
                }
                
                property var stderrCollector: StdioCollector {
                    onStreamFinished: function() {
                        // Only show error if we haven't already successfully processed stdout
                        if (root.isLoading) {
                            console.log("Weather fetch error:", this.text)
                            root.weatherTemp = "Error"
                            root.feelsLikeTemp = "Error"
                            root.weatherIcon = "cloud_off"
                            root.isLoading = false
                        }
                        weatherProc.destroy()
                    }
                }
                
                stdout: stdoutCollector
                stderr: stderrCollector
            }
        `, root)
    }
    
    function getWeatherIcon(weatherCode) {
        // Weather code mapping to Material Design icons
        const codeStr = weatherCode.toString()
        
        // Clear/Sunny
        if (["113"].includes(codeStr)) return "wb_sunny"
        
        // Partly cloudy
        if (["116", "119"].includes(codeStr)) return "partly_cloudy_day"
        
        // Cloudy/Overcast
        if (["122", "143", "248", "260"].includes(codeStr)) return "cloud"
        
        // Rain
        if (["176", "263", "266", "281", "284", "293", "296", "299", "302", "305", "308", "311", "314", "317", "320", "323", "326", "356", "359", "386", "389", "392", "395"].includes(codeStr)) {
            return "rainy"
        }
        
        // Snow
        if (["179", "182", "185", "227", "230", "323", "326", "329", "332", "335", "338", "350", "353", "362", "365", "368", "371", "374", "377", "392", "395"].includes(codeStr)) {
            return "ac_unit"
        }
        
        // Thunderstorm
        if (["200", "386", "389", "392", "395"].includes(codeStr)) return "thunderstorm"
        
        // Fog/Mist
        if (["143", "248", "260"].includes(codeStr)) return "foggy"
        
        // Default
        return "device_thermostat"
    }
    
    RowLayout {
        id: rowLayout
        anchors.centerIn: parent
        spacing: 4
        
        MaterialSymbol {
            id: weatherIconSymbol
            fill: 1
            text: isLoading ? "sync" : weatherIcon
            iconSize: Appearance.font.pixelSize.normal
            color: Appearance.m3colors.m3onSecondaryContainer
            
            // Reset rotation when not loading
            rotation: isLoading ? rotation : 0
            
            RotationAnimation {
                target: weatherIconSymbol
                property: "rotation"
                from: 0
                to: 360
                duration: 1000
                running: isLoading
                loops: Animation.Infinite
            }
        }
        
        Column {
            spacing: 0
            
            StyledText {
                id: tempText
                text: isLoading ? "loading ..." : weatherTemp
                font.pixelSize: Appearance.font.pixelSize.large
                color: Appearance.colors.colOnLayer1
            }
            
            StyledText {
                id: feelsLikeText
                text: isLoading ? "..." : "Feels " + feelsLikeTemp
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnLayer1
                opacity: 0.7
            }
        }
        
        // Optional: Add click to refresh
        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (!isLoading) {
                    fetchLocationAndWeather()
                }
            }
            cursorShape: Qt.PointingHandCursor
        }
    }
}