from pathlib import Path
import subprocess
import tempfile
import unittest

BUILD = Path(__file__).resolve().parents[1] / 'build'


class KeyringSetupTests(unittest.TestCase):
    def run_setup(self, existing=False, fail=''):
        # Stop at /opt preparation, after repository setup. All system commands are mocked.
        script = r'''
set -e
nihil::import() { :; }
source "$1/lib/common.sh"
source "$1/modules/base.sh"
cd() { :; }
sleep() { :; }
pacman() { printf 'PACMAN:%s\n' "$*"; }
grep() {
    if [[ "$*" == *chaotic-aur* ]]; then
        [[ "$EXISTING" == 1 ]]
    else
        return 0
    fi
}
pacman-key() {
    printf 'KEY:%s\n' "$*"
    [[ "$*" != "$FAIL_KEY" ]]
}
timeout() {
    printf 'TIMEOUT:%s\n' "$*"
    shift 2
    "$@"
}
download-retry() {
    [[ "$2" == chaotic-keyring.pkg.tar.zst ]] || return 1
    touch "$2"
}
mkdir() { echo REPOSITORIES_READY; return 1; }
package_base
'''
        with tempfile.TemporaryDirectory() as directory:
            return subprocess.run(['bash', '-c', script, 'test', str(BUILD)], cwd=directory,
                                  env={'PATH': '/usr/bin:/bin', 'EXISTING': str(int(existing)), 'FAIL_KEY': fail},
                                  capture_output=True, text=True)

    def test_new_repository_initializes_before_signing_and_populates_installed_keys(self):
        result = self.run_setup()
        keys = [line for line in result.stdout.splitlines() if line.startswith('KEY:')]
        self.assertEqual(keys, [
            'KEY:--init', 'KEY:--populate archlinux',
            'KEY:--recv-key 3056513887B78AEB --keyserver hkps://keyserver.ubuntu.com',
            'KEY:--lsign-key 3056513887B78AEB', 'KEY:--populate chaotic',
        ])
        self.assertIn('TIMEOUT:--kill-after=5s 60s pacman-key --recv-key', result.stdout)
        self.assertIn('REPOSITORIES_READY', result.stdout)

    def test_existing_repository_is_repopulated_without_keyserver_lookup(self):
        result = self.run_setup(existing=True)
        keys = [line for line in result.stdout.splitlines() if line.startswith('KEY:')]
        self.assertEqual(keys, ['KEY:--init', 'KEY:--populate archlinux', 'KEY:--populate chaotic'])
        self.assertIn('REPOSITORIES_READY', result.stdout)
        self.assertNotIn('TIMEOUT:', result.stdout)

    def test_keyring_failures_stop_before_tools(self):
        for failure in ('--init', '--populate archlinux', '--populate chaotic',
                        '--recv-key 3056513887B78AEB --keyserver hkps://keyserver.ubuntu.com',
                        '--lsign-key 3056513887B78AEB'):
            with self.subTest(failure=failure):
                result = self.run_setup(fail=failure)
                self.assertNotEqual(result.returncode, 0)
                self.assertNotIn('REPOSITORIES_READY', result.stdout)


if __name__ == '__main__':
    unittest.main()
