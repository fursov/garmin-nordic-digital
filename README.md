# Nordic Digital

Minimalist AMOLED watch face for **Garmin vívoactive 6**, with two values from
[Garmin Data Bridge](https://github.com/fursov/ha-garmin-data-bridge).

> Prototype v0.1.0. The first priority is a real Garmin SDK build and basic
> simulator/device validation. The layout is intentionally restrained.

## What is displayed

- Large 24-hour time and local date
- First two exposed Home Assistant states (profile ordering from the Bridge)
- Watch battery percentage, obtained locally from Garmin
- Small green/gray indicator: Home Assistant data fresh/old
- Dimmed time/date-only low-power view; no remote values or network in AOD

All Home Assistant entity IDs remain configured **in Home Assistant**, not in
the watch face. The first two positions in the Bridge's selected entity list
are the two remote slots on the watch.

## Network and security

The watch face registers a periodic Connect IQ background event every
**10 minutes**. Garmin may delay background events. The background service
sends one HTTPS request through the Connect IQ transport:

```http
GET https://YOUR_HOME_ASSISTANT/api/garmin_data_bridge/v1/data
Authorization: Bearer YOUR_BRIDGE_PROFILE_TOKEN
Accept: application/json
```

Only two minimal display values (not the full response) cross into the
watch-face process. The app caches the most recent good payload; if a request
fails, the clock remains functional and cached values are retained, with
a stale indicator after 60 minutes.

The bridge token belongs to a dedicated read-only Garmin profile. **Never**
commit a real token or domain to this repository. The Garmin settings form
stores a token on the watch as an application property. Keep your watch and
paired phone secure; rotate the Bridge profile token if the watch is lost.
Use a valid public HTTPS certificate on the HA domain.

## Build and run

1. Install [Connect IQ SDK 9.3.0](https://developer.garmin.com/connect-iq/sdk/)
   and the **vívoactive 6** device definition using SDK Manager.
2. Install the Garmin Monkey C extension in VS Code.
3. Open this folder as a Connect IQ project.
4. Create a private developer signing key (do not commit it).
5. Run the `vivoactive6` target in the Garmin simulator. Use
   **Simulation → Trigger Background Event** to exercise the API request.
6. Configure `haUrl` and `apiToken` in the app properties in the simulator
   and restart/trigger the background event.

You can compile manually:

```bash
monkeyc -f monkey.jungle -d vivoactive6 -o NordicDigital.prg -y /path/to/developer_key.der
```

**Important for side-loading:** Garmin Connect IQ's settings UI for watch faces
may not be available on a manually side-loaded `.prg`. The documented
mobile configuration path is to upload an **unlisted/beta** build to Connect IQ
Store, then configure `Home Assistant HTTPS URL` and `Garmin Data Bridge
token` in the Connect IQ app. The simulator can use its editable persistent
application properties before Store publishing. Do not hard-code production
credentials to get around this limitation.

## API payload (example)

```json
{
  "version": 1,
  "generated_at": "2026-11-13T12:00:00+02:00",
  "items": [
    {"slot": 1, "label": "Outdoor", "value": "4.1", "unit": "°C", "status": "ok"},
    {"slot": 2, "label": "Price", "value": "8.4", "unit": "c/kWh", "status": "ok"}
  ]
}
```

## Planned follow-ups

- Confirm layout and power consumption on physical vívoactive 6
- Polish typography, better unit display, optional price accent colors
- Support precise short labels configured through the HA integration
- Investigate token pairing without typing a long secret
- Add real Monkey C simulator tests to CI

## Validation

GitHub Actions runs fast contract tests and **compiles with the official Garmin
SDK**. A passing build doesn't replace testing background networking and AOD
rendering on a physical Garmin watch.
