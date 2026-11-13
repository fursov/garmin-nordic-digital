"""Fast static contract tests; actual Monkey C compilation is a separate CI job."""

import pathlib
import unittest
import xml.etree.ElementTree as ET

ROOT = pathlib.Path(__file__).resolve().parents[1]


class WatchFaceProjectTests(unittest.TestCase):
    def test_manifest_has_vivoactive6_and_only_required_permissions(self):
        ns = {"iq": "http://www.garmin.com/xml/connectiq"}
        root = ET.parse(ROOT / "manifest.xml").getroot()
        app = root.find("iq:application", ns)
        self.assertEqual(app.attrib["type"], "watchface")
        self.assertEqual(app.attrib["entry"], "NordicDigitalApp")
        self.assertEqual(
            [p.attrib["id"] for p in app.findall("iq:products/iq:product", ns)],
            ["vivoactive6"],
        )
        self.assertEqual(
            sorted(
                p.attrib["id"]
                for p in app.findall("iq:permissions/iq:uses-permission", ns)
            ),
            ["Background", "Communications"],
        )

    def test_settings_and_properties_agree(self):
        ns = {}
        properties = ET.parse(
            ROOT / "resources/settings/properties.xml"
        ).getroot()
        settings = ET.parse(ROOT / "resources/settings/settings.xml").getroot()
        keys = {p.attrib["id"] for p in properties.findall(".//property")}
        self.assertEqual(keys, {"haUrl", "apiToken"})
        for item in settings.findall(".//setting"):
            self.assertIn(item.attrib["propertyKey"].replace("@Properties.", ""), keys)

    def test_network_calls_only_from_background_and_no_embedded_credentials(self):
        source = ROOT / "source"
        network = [
            p.name for p in source.glob("*.mc")
            if "makeWebRequest(" in p.read_text(encoding="utf8")
        ]
        self.assertEqual(network, ["GarminBridgeService.mc"])
        service = (source / network[0]).read_text(encoding="utf8")
        self.assertIn("(:background)", service)
        self.assertIn("Authorization", service)
        self.assertIn("https://", service)
        self.assertNotIn("http://", service)
        self.assertIn("Background.exit(", service)

    def test_bridge_contract(self):
        service = (ROOT / "source/GarminBridgeService.mc").read_text()
        self.assertIn("/api/garmin_data_bridge/v1/data", service)
        self.assertIn('data["version"] != 1', service)
        self.assertIn('data["items"]', service)
        self.assertIn("i < 2", service)


if __name__ == "__main__":
    unittest.main()
