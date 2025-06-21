pragma Singleton
pragma ComponentBehavior: Bound

import "root:/modules/common/functions/string_utils.js" as StringUtils
import "root:/modules/common/functions/object_utils.js" as ObjectUtils
import "root:/modules/common"
import Quickshell;
import Quickshell.Io;
import Qt.labs.platform
import QtQuick;

/**
 * Basic service to handle weather api integration.
 */
Singleton {
    id: root

    function updateWeatherForCity(city) {
        const cityCommmandString = `curl ipinfo.io`;
        const requestCommandString = `curl --no-buffer "${endpoint}"`;
    }
}