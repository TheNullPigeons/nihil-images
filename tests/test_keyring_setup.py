from pathlib import Path
import subprocess
import tempfile
import unittest

BUILD = Path(__file__).resolve().parents[1] / 'build'


class KeyringSetupTests(unittest.TestCase):
    def run_setup(self, existing=False, fail='', key_mode='valid', download_fails=False):
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
    [[ "$1" != "$FAIL_KEY" && "$*" != "$FAIL_KEY" ]]
}
curl() {
    printf 'CURL:%s\n' "$*"
    [[ "$DOWNLOAD_FAILS" == 0 ]]
}
gpg() {
    [[ "$KEY_MODE" != invalid ]] || return 2
    printf 'pub:::::::::\nfpr:::::::::%s:\n' "${FINGERPRINT}"
    if [[ "$KEY_MODE" == multiple ]]; then
        printf 'pub:::::::::\nfpr:::::::::%s:\n' "${FINGERPRINT}"
    fi
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
                                  env={'PATH': '/usr/bin:/bin', 'EXISTING': str(int(existing)), 'FAIL_KEY': fail,
                                       'KEY_MODE': key_mode, 'DOWNLOAD_FAILS': str(int(download_fails)),
                                       'FINGERPRINT': 'BAD' if key_mode == 'wrong' else
                                           'EF925EA60F33D0CB85C44AD13056513887B78AEB'},
                                  capture_output=True, text=True)

    def test_new_repository_initializes_before_signing_and_populates_installed_keys(self):
        result = self.run_setup()
        keys = [line for line in result.stdout.splitlines() if line.startswith('KEY:')]
        self.assertEqual(keys[:2], ['KEY:--init', 'KEY:--populate archlinux'])
        self.assertTrue(keys[2].startswith('KEY:--add '))
        self.assertEqual(keys[3:], [
            'KEY:--lsign-key EF925EA60F33D0CB85C44AD13056513887B78AEB', 'KEY:--populate chaotic',
        ])
        self.assertIn('--connect-timeout 10 --max-time 60', result.stdout)
        self.assertIn('https://raw.githubusercontent.com/chaotic-aur/keyring/master/master/pedrohlc.asc', result.stdout)
        self.assertIn('REPOSITORIES_READY', result.stdout)

    def test_existing_repository_is_repopulated_without_keyserver_lookup(self):
        result = self.run_setup(existing=True)
        keys = [line for line in result.stdout.splitlines() if line.startswith('KEY:')]
        self.assertEqual(keys, ['KEY:--init', 'KEY:--populate archlinux', 'KEY:--populate chaotic'])
        self.assertIn('REPOSITORIES_READY', result.stdout)
        self.assertNotIn('CURL:', result.stdout)

    def test_keyring_failures_stop_before_tools(self):
        for failure in ('--init', '--populate archlinux', '--populate chaotic',
                        '--add', '--lsign-key EF925EA60F33D0CB85C44AD13056513887B78AEB'):
            with self.subTest(failure=failure):
                result = self.run_setup(fail=failure)
                self.assertNotEqual(result.returncode, 0)
                self.assertNotIn('REPOSITORIES_READY', result.stdout)

    def test_unexpected_or_multiple_primary_keys_are_rejected_before_import(self):
        for mode in ('wrong', 'multiple', 'invalid'):
            with self.subTest(mode=mode):
                result = self.run_setup(key_mode=mode)
                self.assertNotIn('KEY:--add', result.stdout)
                self.assertNotIn('REPOSITORIES_READY', result.stdout)
                self.assertIn('Unexpected Chaotic-AUR signing-key fingerprint', result.stdout)

    def test_download_failure_is_retried_and_stops_before_import(self):
        result = self.run_setup(download_fails=True)
        self.assertEqual(result.stdout.count('CURL:'), 3)
        self.assertNotIn('KEY:--add', result.stdout)
        self.assertNotIn('REPOSITORIES_READY', result.stdout)


if __name__ == '__main__':
    unittest.main()
