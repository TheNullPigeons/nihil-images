import importlib.util
import json
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest

BUILD = Path(__file__).resolve().parents[1] / 'build'
spec = importlib.util.spec_from_file_location('tool_selection', BUILD / 'lib/tool_selection.py')
selection = importlib.util.module_from_spec(spec)
spec.loader.exec_module(selection)
MANIFEST = json.loads((BUILD / 'config/tools.json').read_text())


class ToolSelectionTests(unittest.TestCase):
    def run_shell(self, selected, script, manifest=None):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            shutil.copytree(BUILD / 'lib', root / 'lib')
            shutil.copytree(BUILD / 'modules', root / 'modules')
            (root / 'config').mkdir()
            (root / 'config/tools.json').write_text(json.dumps(MANIFEST if manifest is None else manifest))
            if selected is not None:
                (root / 'config/tool-selection.json').write_text(json.dumps(selected))
            setup = '''set -e
NIHIL_BUILD="$2"
source "$2/lib/loader.sh"
for module in "$2"/modules/*.sh; do nihil::import "modules/$(basename "$module" .sh)"; done
nihil::import lib/tool_selection
nihil::import lib/healthcheck
tool_selection_prepare
'''
            return subprocess.run(['bash', '-c', setup + script, 'test', str(BUILD), str(root)],
                                  capture_output=True, text=True)

    def test_every_single_tool_has_a_callable_provider(self):
        # Validate real Bash definitions, including providers shared across modules.
        result = self.run_shell(None, ':')
        self.assertEqual(result.returncode, 0, result.stderr)
        for module, tools in MANIFEST.items():
            for tool in tools:
                with self.subTest(tool=tool['name']):
                    plan = selection.plan_tools(MANIFEST, {'enabled_tools': [tool['name']]})
                    self.assertIn((module, tool['name'], tool['installer'], True), plan)
                    self.assertTrue(all(active for mod, _, _, active in plan if mod == 'core_tools'))

    def test_shared_providers_and_wes_are_dispatched_once_in_order(self):
        selected = ['wesng', 'john', 'zip2john', 'rockyou', 'pycdc', 'pycdas', 'xortool-xor']
        script = '''
install_wes() { echo CALL:wes; }
install_john() { echo CALL:john; }
install_xortool() { echo CALL:xortool; }
install_seclists() { echo CALL:seclists; }
install_pycdc() { echo CALL:pycdc; }
install_selected_tools mod_misc
install_selected_tools mod_credential
install_selected_tools mod_wordlists
install_selected_tools mod_reverse
'''
        result = self.run_shell({'enabled_tools': selected}, script)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual([s for s in result.stdout.splitlines() if s.startswith('CALL:')],
                         ['CALL:wes', 'CALL:xortool', 'CALL:john', 'CALL:seclists', 'CALL:pycdc'])

    def test_dependencies_are_not_filtered(self):
        result = self.run_shell({'enabled_tools': ['bloodhound-ce']}, '''
install_neo4j() { echo CALL:dependency; }
install_bloodhound_ce_desktop() { install_neo4j; echo CALL:bloodhound; }
install_selected_tools mod_ad
''')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('CALL:dependency\nCALL:bloodhound', result.stdout)

    def test_dependency_failure_stops_the_build(self):
        result = self.run_shell({'enabled_tools': ['wesng']}, '''
install_wes() { false; echo SHOULD_NOT_RUN; }
install_selected_tools mod_misc
echo SHOULD_NOT_RUN
''')
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn('SHOULD_NOT_RUN', result.stdout)

    def test_empty_selection_keeps_only_core_and_legacy_disable_still_works(self):
        plan = selection.plan_tools(MANIFEST, {'enabled_tools': []})
        self.assertTrue(all(active == (module == 'core_tools') for module, _, _, active in plan))
        plan = selection.plan_tools(MANIFEST, {'disabled_tools': ['wesng', 'vim']})
        self.assertFalse(next(active for _, name, _, active in plan if name == 'wesng'))
        self.assertTrue(next(active for _, name, _, active in plan if name == 'vim'))
        self.assertTrue(all(active for *_, active in selection.plan_tools(MANIFEST)))

    def test_invalid_configuration_fails_before_any_installer(self):
        for value in ({'enabled_tools': 'wesng'}, {'enabled_tools': ['missing']}, [],
                      {'enabled_tools': [42]}):
            with self.subTest(value=value), self.assertRaises(ValueError):
                selection.plan_tools(MANIFEST, value)
        bad = {'mod_misc': [{'name': 'wesng', 'installer': 'install_missing'}]}
        result = self.run_shell(None, 'echo SHOULD_NOT_RUN', bad)
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn('SHOULD_NOT_RUN', result.stdout)
        bad['mod_misc'][0]['installer'] = 'install_wes; touch /tmp/unsafe'
        with self.assertRaises(ValueError):
            selection.plan_tools(bad)

    def test_base_bootstrap_does_not_require_python(self):
        result = self.run_shell(None, """
entrypoint="$1/entrypoint.sh"
cd "$2"
package_base() { echo BASE_BOOTSTRAPPED; }
python3() { echo PYTHON_SHOULD_NOT_RUN >&2; return 127; }
set -- package_base
source "$entrypoint"
""")
        self.assertNotIn('PYTHON_SHOULD_NOT_RUN', result.stderr)
        # The entrypoint also requires root; the stub is safe on root CI runners.
        import os
        if os.geteuid() == 0:
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn('BASE_BOOTSTRAPPED', result.stdout)
        else:
            self.assertIn('This script must be run as root', result.stdout)

    def test_variant_filter_keeps_selection_valid_for_next_build_step(self):
        result = self.run_shell({'enabled_tools': ['wesng', 'nmap', 'pycdc']}, """
filter_tools_json core_tools mod_misc
tool_selection_prepare
tool_selection_enabled_name wesng
if tool_selection_enabled_name nmap; then exit 1; fi
""")
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_variant_modules_dispatch_without_running_real_installers(self):
        providers = {tool['installer'] for tools in MANIFEST.values() for tool in tools}
        stubs = '\n'.join(f'{provider}() {{ echo CALL:{provider}; }}' for provider in providers)
        # Module preparation is stubbed too: this test checks actual dispatch, not package installs.
        stubs += '\ninstall_cyrus_sasl_gssapi() { :; }\ninstall_python_pcapy() { :; }\n'
        stubs += 'install_python_lxml() { :; }\n_ensure_lists_dir() { :; }\nadd-aliases() { :; }\n'
        for variant in ('Dockerfile', 'Dockerfile.ad', 'Dockerfile.web', 'Dockerfile.blueteam'):
            modules = re.findall(r'entrypoint.sh (install_core_tools|install_mod_\w+)',
                                 (BUILD.parent / variant).read_text())
            result = self.run_shell(None, stubs + '\n' + '\n'.join(modules))
            self.assertEqual(result.returncode, 0, (variant, result.stderr))
            calls = [line.removeprefix('CALL:') for line in result.stdout.splitlines() if line.startswith('CALL:')]
            expected = []
            for entrypoint in modules:
                category = entrypoint.removeprefix('install_')
                expected += list(dict.fromkeys(t['installer'] for t in MANIFEST[category]))
            self.assertEqual(calls, expected, variant)


if __name__ == '__main__':
    unittest.main()
