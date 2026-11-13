import Toybox.Application;
import Toybox.Graphics;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

class NordicDigitalView extends WatchUi.WatchFace {
    var _dimmed = false;

    function initialize() {
        WatchFace.initialize();
    }

    function onEnterSleep() {
        _dimmed = true;
    }

    function onExitSleep() {
        _dimmed = false;
    }

    function onUpdate(dc) {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var center = width / 2;
        var now = Time.now();
        var date = Gregorian.info(now, Time.FORMAT_MEDIUM);
        var timeText = date.hour.format("%02d") + ":" + date.min.format("%02d");
        var muted = _dimmed ? 0x777F88 : 0x9EA8B2;
        var primary = _dimmed ? 0x9EA8B2 : 0xF2F6FA;

        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Keep the always-on view restrained. A small shifting offset reduces
        // the time spent illuminating exactly the same AMOLED pixels.
        var offset = 0;
        if (_dimmed) {
            offset = ((date.min % 3) - 1) * 2;
        }

        dc.setColor(muted, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            center + offset,
            height * 21 / 100,
            Graphics.FONT_SMALL,
            date.day_of_week + "  " + date.day + " " + date.month,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        dc.setColor(primary, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            center + offset,
            height * 34 / 100,
            Graphics.FONT_NUMBER_THAI_HOT,
            timeText,
            Graphics.TEXT_JUSTIFY_CENTER
        );

        if (_dimmed) {
            return;
        }

        // The watch displays the last known good values while offline.
        var snapshot = Application.Storage.getValue("snapshot");
        var stale = true;
        var slots = null;
        if (snapshot instanceof Dictionary &&
            snapshot.hasKey("time") && snapshot.hasKey("items")) {
            var then = snapshot["time"];
            if (then instanceof Number) {
                var age = now.value() - then;
                stale = age < 0 || age > 3600;
            }
            slots = snapshot["items"];
        }

        dc.setColor(0x303942, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(width * 17 / 100, height * 62 / 100,
                    width * 83 / 100, height * 62 / 100);

        var left = width * 25 / 100;
        var middle = width * 50 / 100;
        var right = width * 75 / 100;
        drawRemoteSlot(dc, left, height, slots, 0, "HA 1", stale);
        drawRemoteSlot(dc, middle, height, slots, 1, "HA 2", stale);

        var percent = System.getSystemStats().battery.toNumber().format("%d") + "%";
        dc.setColor(0xC7D9D0, Graphics.COLOR_TRANSPARENT);
        dc.drawText(right, height * 68 / 100, Graphics.FONT_SMALL,
                    percent, Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(muted, Graphics.COLOR_TRANSPARENT);
        dc.drawText(right, height * 77 / 100, Graphics.FONT_TINY,
                    "BATTERY", Graphics.TEXT_JUSTIFY_CENTER);

        // A quiet freshness indicator, rather than a large error message.
        dc.setColor(stale ? 0x555D66 : 0x7DB69E,
                    Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(center, height * 87 / 100, 3);
    }

    function drawRemoteSlot(dc, x, height, slots, index, fallback, stale) {
        var value = "--";
        var label = fallback;

        if (slots instanceof Array && slots.size() > index) {
            var item = slots[index];
            if (item instanceof Dictionary) {
                if (item.hasKey("label") && item["label"] instanceof String) {
                    label = item["label"];
                }
                if (item.hasKey("status") && item["status"] == "ok" &&
                    item.hasKey("value") && item["value"] instanceof String) {
                    value = item["value"];
                }
            }
        }

        // Long Home Assistant names are abbreviated. The Bridge configuration
        // remains the authority on which sensors are exposed.
        if (label.length() > 9) {
            label = label.substring(0, 9);
        }
        if (value.length() > 8) {
            value = value.substring(0, 8);
        }

        dc.setColor(stale ? 0x85909A : 0xDFE7EF, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, height * 68 / 100, Graphics.FONT_SMALL,
                    value, Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(0x8C98A3, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, height * 77 / 100, Graphics.FONT_TINY,
                    label, Graphics.TEXT_JUSTIFY_CENTER);
    }
}
