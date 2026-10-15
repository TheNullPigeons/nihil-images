import importlib.util
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch


ASSETS = Path(__file__).resolve().parents[1] / "build/assets/firefox"
spec = importlib.util.spec_from_file_location("generate_policy", ASSETS / "generate_policy.py")
policy = importlib.util.module_from_spec(spec)
spec.loader.exec_module(policy)


class FirefoxPolicyTests(unittest.TestCase):
    def test_guid_comes_from_json_api(self):
        with patch.object(policy.urllib.request, "urlopen", return_value=io.BytesIO(
            b'{"guid": "foxyproxy@eric.h.jung"}'
        )) as request:
            self.assertEqual(policy.get_extension_guid("foxyproxy-standard"), "foxyproxy@eric.h.jung")
        self.assertEqual(request.call_args.args[0].full_url,
                         "https://addons.mozilla.org/api/v5/addons/addon/foxyproxy-standard/")

    def test_invalid_guid_is_rejected(self):
        for guid in (None, "", " ", 42):
            with self.subTest(guid=guid), patch.object(
                policy.urllib.request, "urlopen",
                return_value=io.BytesIO(json.dumps({"guid": guid}).encode()),
            ), self.assertRaises(RuntimeError):
                policy.get_extension_guid("foxyproxy-standard")

    def test_all_extensions_are_kept_and_failure_preserves_policy(self):
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory) / "policies.json"
            with patch.object(policy, "TEMPLATE_PATH", ASSETS / "policies.json.template"), \
                 patch.object(policy, "POLICY_PATH", str(target)), \
                 patch.object(policy, "get_extension_guid", side_effect=lambda slug: slug):
                policy.main()
                settings = json.loads(target.read_text())["policies"]["ExtensionSettings"]
                self.assertEqual(set(settings), {ext["slug"] for ext in policy.EXTENSIONS})
                for ext in policy.EXTENSIONS:
                    self.assertEqual(settings[ext["slug"]]["installation_mode"], ext["mode"])
                    self.assertEqual(settings[ext["slug"]].get("default_area") == "navbar", ext["pin"])
                original = target.read_text()
                with patch.object(policy, "get_extension_guid", side_effect=OSError("AMO unavailable")), \
                     self.assertRaises(OSError):
                    policy.main()
                self.assertEqual(target.read_text(), original)


if __name__ == "__main__":
    unittest.main()
