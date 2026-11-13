import Toybox.Application;
import Toybox.Background;
import Toybox.Communications;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;

// Only background code can make network requests for a watch face.
// Deliberately transfer two small display slots rather than the entire
// Home Assistant JSON response to the foreground process.
(:background)
class GarminBridgeService extends System.ServiceDelegate {
    function initialize() {
        ServiceDelegate.initialize();
    }

    function onTemporalEvent() {
        var host = Application.Properties.getValue("haUrl");
        var token = Application.Properties.getValue("apiToken");

        if (!(host instanceof String) || !(token instanceof String)) {
            Background.exit({"error" => "not_configured"});
            return;
        }

        if (host.length() < 9 || host.substring(0, 8) != "https://" ||
            token.length() == 0) {
            Background.exit({"error" => "not_configured"});
            return;
        }

        // Accept the Home Assistant HTTPS origin, not a hard-coded domain.
        // Trailing slash is tolerated so users can paste their usual URL.
        if (host.substring(host.length() - 1, host.length()) == "/") {
            host = host.substring(0, host.length() - 1);
        }

        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_GET,
            :headers => {
                "Authorization" => "Bearer " + token,
                "Accept" => "application/json"
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        Communications.makeWebRequest(
            host + "/api/garmin_data_bridge/v1/data",
            null,
            options,
            method(:onResponse)
        );
    }

    function onResponse(responseCode as Number, data as Dictionary?) as Void {
        if (responseCode != 200 || !(data instanceof Dictionary)) {
            Background.exit({"error" => responseCode});
            return;
        }
        if (!data.hasKey("version") || data["version"] != 1 ||
            !data.hasKey("items") || !(data["items"] instanceof Array)) {
            Background.exit({"error" => "invalid_response"});
            return;
        }

        var source = data["items"] as Array;
        var slots = [];
        for (var i = 0; i < source.size() && i < 2; i++) {
            var item = source[i];
            if (!(item instanceof Dictionary)) {
                continue;
            }

            var value = item.hasKey("value") ? item["value"] : null;
            var label = item.hasKey("label") ? item["label"] : null;
            var unit = item.hasKey("unit") ? item["unit"] : null;
            var status = item.hasKey("status") ? item["status"] : null;

            slots.add({
                "value" => shortText(value, 9),
                "label" => shortText(label, 10),
                "unit" => shortText(unit, 7),
                "status" => status == "ok" ? "ok" : "unavailable"
            });
        }
        Background.exit({
            "items" => slots,
            "time" => Time.now().value()
        });
    }

    function shortText(value, maxLength) {
        if (!(value instanceof String)) {
            return "";
        }
        if (value.length() > maxLength) {
            return value.substring(0, maxLength);
        }
        return value;
    }
}
