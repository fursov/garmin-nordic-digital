import Toybox.Application;
import Toybox.Background;
import Toybox.Time;
import Toybox.WatchUi;

// The application must be available to the background process so Garmin can
// construct the ServiceDelegate independently of the watch-face view.
(:background)
class NordicDigitalApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        // A watch face may use the network only in its background service.
        // The event is registered only once, for the active watch face.
        if (Background.getTemporalEventRegisteredTime() == null) {
            Background.registerForTemporalEvent(new Time.Duration(10 * 60));
        }
        return [new NordicDigitalView()];
    }

    function getServiceDelegate() {
        return [new GarminBridgeService()];
    }

    function onBackgroundData(data) {
        // Keep the last GOOD payload on errors or when the phone is offline.
        // Never persist the token, server URL, or a raw HTTP response.
        if (data instanceof Dictionary && data.hasKey("items")) {
            Application.Storage.setValue("snapshot", data);
        }
        WatchUi.requestUpdate();
    }

    function onSettingsChanged() {
        // A newly configured endpoint/profile must not expose cached data
        // from a previously configured Home Assistant profile.
        Application.Storage.deleteValue("snapshot");
        WatchUi.requestUpdate();
    }
}
