import os
import pty
from pathlib import Path
import select
import signal
import subprocess
import tempfile
import time
import unittest


LAUNCHER = Path(__file__).resolve().parents[1] / "build/lib/installers/bloodhound-ce/bloodhound-ce"


class BloodHoundLauncherTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.binary = self.root / "bloodhound"
        self.binary.write_text("""#!/usr/bin/env python3
import os
import signal
import sys
import time
if "-help" in sys.argv:
    print("BloodHound help")
elif "-version" in sys.argv:
    print("BloodHound version")
else:
    print("admin env:", repr((os.getenv("BHE_DEFAULT_ADMIN_PASSWORD"), os.getenv("BHE_DEFAULT_ADMIN_EXPIRE_NOW"))), file=sys.stderr, flush=True)
    print("arguments:", repr(sys.argv[1:]), file=sys.stderr, flush=True)
    print('{"level":"INFO","message":"routine log"}', flush=True)
    if os.environ.get("BHCE_TEST_DELAY_PASSWORD"):
        time.sleep(0.5)
    if os.environ.get("BHCE_TEST_CONFIGURED"):
        print("Password has been set from existing config or environment variable", flush=True)
    else:
        print("# Initial Password Set To:    fixture-password    #", flush=True)
    print('{"level":"ERROR","message":"fixture error"}', file=sys.stderr, flush=True)
    print("fixture diagnostic", file=sys.stderr, flush=True)
    if os.environ.get("BHCE_TEST_WAIT"):
        print("ready", flush=True)
        if os.environ.get("BHCE_TEST_IGNORE_SIGNALS"):
            signal.signal(signal.SIGINT, signal.SIG_IGN)
        signal.pause()
    else:
        sys.exit(23)
""")
        self.binary.chmod(0o755)
        self.config = self.root / "config.json"
        self.config.write_text('{"root_url":"http://localhost:1030"}')
        source = LAUNCHER.read_text()
        source = source.replace(
            'BHCE_BIN="/opt/tools/BloodHound-CE/bloodhound"',
            f'BHCE_BIN="{self.binary}"',
        ).replace(
            'BHCE_CFG="/opt/tools/BloodHound-CE/bloodhound.config.json"',
            f'BHCE_CFG="{self.config}"',
        )
        start = source.index("export NEO4J_HOME")
        end = source.index("# Bail early", start)
        source = source[:start] + f'export NEO4J_HOME="{self.root}"\n' + source[end:]
        self.launcher = self.root / "launcher"
        self.launcher.write_text(source)
        for name, body in {
            "ss": 'echo ":7687"',
            "neo4j": 'echo "is running"',
            "pg_isready": "exit 0",
        }.items():
            stub = self.root / name
            stub.write_text("#!/bin/sh\n" + body + "\n")
            stub.chmod(0o755)
        (self.root / "bin").mkdir()
        (self.root / "bin/neo4j").symlink_to(self.root / "neo4j")
        self.env = {**os.environ, "PATH": f"{self.root}:{os.environ['PATH']}"}

    def run_launcher(self, *args):
        return subprocess.run(
            ["bash", str(self.launcher), *args], env=self.env,
            capture_output=True, text=True, timeout=5,
        )

    def test_default_is_silent_after_password_and_preserves_exit_status(self):
        result = self.run_launcher()
        self.assertEqual(result.returncode, 23)
        self.assertNotIn("[nihil] Starting BloodHound CE...", result.stdout)
        self.assertIn("http://localhost:1030", result.stdout)
        self.assertIn("Password: fixture-password", result.stdout)
        self.assertNotIn("routine log", result.stdout + result.stderr)
        self.assertNotIn("fixture error", result.stdout + result.stderr)
        self.assertNotIn("fixture diagnostic", result.stdout + result.stderr)
        self.assertTrue(result.stdout.rstrip().endswith("Password: fixture-password"))

    def test_password_clears_spinner_line_in_terminal(self):
        master, slave = pty.openpty()
        try:
            with subprocess.Popen(
                ["bash", str(self.launcher)],
                env={**self.env, "BHCE_TEST_DELAY_PASSWORD": "1"},
                stdout=slave, stderr=slave,
            ) as process:
                os.close(slave)
                slave = None
                self.assertEqual(process.wait(timeout=5), 23)
                output = b""
                while select.select([master], [], [], 0.1)[0]:
                    try:
                        output += os.read(master, 4096)
                    except OSError:
                        break
                self.assertIn(b"\r\x1b[2KPassword: fixture-password", output)
                self.assertIn("⠋ Starting BloodHound CE".encode(), output)
        finally:
            os.close(master)
            if slave is not None:
                os.close(slave)

    def test_fixed_initial_password_can_be_overridden(self):
        self.env["BHCE_TEST_CONFIGURED"] = "1"
        self.env.pop("BHE_DEFAULT_ADMIN_PASSWORD", None)
        self.env.pop("BHE_DEFAULT_ADMIN_EXPIRE_NOW", None)
        result = self.run_launcher()
        self.assertIn("Password: fly2own", result.stdout)
        self.assertNotIn("Password has been set", result.stdout + result.stderr)
        self.env["BHE_DEFAULT_ADMIN_PASSWORD"] = "custom fixture password"
        self.env["BHE_DEFAULT_ADMIN_EXPIRE_NOW"] = "true"
        result = self.run_launcher()
        self.assertIn("Password: custom fixture password", result.stdout)
        verbose = self.run_launcher("--verbose")
        self.assertIn("admin env: ('custom fixture password', 'true')", verbose.stderr)

    def test_neo4j_stopping_during_startup_is_restarted(self):
        marker = self.root / "neo4j-ready"
        checked = self.root / "neo4j-checked"
        (self.root / "ss").write_text(
            f'#!/bin/sh\n[ -f "{marker}" ] && echo ":7687"\n'
        )
        (self.root / "neo4j").write_text(
            f'#!/bin/sh\n'
            f'if [ "$1" = start ]; then touch "{marker}"; exit 0; fi\n'
            f'if [ ! -f "{checked}" ]; then touch "{checked}"; echo "is running"; fi\n'
        )
        sleeper = self.root / "sleep"
        sleeper.write_text("#!/bin/sh\nexit 0\n")
        sleeper.chmod(0o755)
        result = self.run_launcher()
        self.assertEqual(result.returncode, 23)
        self.assertIn("Waiting for Neo4j", result.stdout)
        self.assertIn("Starting Neo4j", result.stdout)
        self.assertTrue(marker.exists())

    def test_verbose_passes_original_output(self):
        result = self.run_launcher("--verbose")
        self.assertEqual(result.returncode, 23)
        self.assertIn("routine log", result.stdout)
        self.assertIn("# Initial Password Set To:", result.stdout)
        self.assertIn("fixture error", result.stderr)
        self.assertIn("fixture diagnostic", result.stderr)
        self.assertNotIn("Password: fixture-password", result.stdout)

    def test_help_and_version_bypass_startup(self):
        for option, expected in (("--help", "help"), ("-h", "help"), ("-version", "version")):
            with self.subTest(option=option):
                result = self.run_launcher(option)
                self.assertEqual(result.returncode, 0)
                self.assertIn(f"BloodHound {expected}", result.stdout)
                self.assertNotIn("Starting", result.stdout)

    def test_custom_config_and_remaining_arguments(self):
        config = self.root / "custom config.json"
        config.write_text('{"root_url":"http://localhost:1040"}')
        for arguments in (
            ("-configfile", str(config)),
            (f"--configfile={config}",),
        ):
            with self.subTest(arguments=arguments):
                result = self.run_launcher(*arguments, "--unknown-option")
                self.assertEqual(result.returncode, 23)
                self.assertIn("http://localhost:1040", result.stdout)
                self.assertNotIn("arguments:", result.stdout + result.stderr)
                verbose = self.run_launcher(*arguments, "--unknown-option", "--verbose")
                self.assertIn(
                    repr(["-configfile", str(config), "--unknown-option"]), verbose.stderr
                )

    def test_config_option_requires_a_path(self):
        result = self.run_launcher("-configfile")
        self.assertEqual(result.returncode, 2)
        self.assertIn("requires a file path", result.stderr)
        self.assertNotIn("Starting", result.stdout)

    def test_term_reaches_bloodhound(self):
        with subprocess.Popen(
            ["bash", str(self.launcher), "--verbose"],
            env={**self.env, "BHCE_TEST_WAIT": "1"},
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
        ) as process:
            try:
                for line in process.stdout:
                    if line.strip() == "ready":
                        break
                else:
                    self.fail("mock BloodHound did not start")
                process.terminate()
                process.communicate(timeout=5)
                self.assertEqual(process.returncode, -signal.SIGTERM)
            finally:
                if process.poll() is None:
                    process.kill()

    def test_ctrl_c_stops_unresponsive_bloodhound(self):
        master, slave = pty.openpty()
        try:
            with subprocess.Popen(
                ["bash", str(self.launcher)],
                env={**self.env, "BHCE_TEST_WAIT": "1", "BHCE_TEST_IGNORE_SIGNALS": "1"},
                stdout=subprocess.PIPE, stderr=slave, text=True,
                start_new_session=True,
            ) as process:
                os.close(slave)
                slave = None
                try:
                    for line in process.stdout:
                        if "Password: fixture-password" in line:
                            break
                    else:
                        self.fail("mock BloodHound did not start")
                    output = b""
                    until = time.monotonic() + 3
                    while "⠋ Starting BloodHound CE".encode() not in output and time.monotonic() < until:
                        if select.select([master], [], [], 0.25)[0]:
                            output += os.read(master, 4096)
                    self.assertIn("⠋ Starting BloodHound CE".encode(), output)
                    os.killpg(process.pid, signal.SIGINT)
                    process.communicate(timeout=5)
                    self.assertEqual(process.returncode, 130)
                finally:
                    if process.poll() is None:
                        os.killpg(process.pid, signal.SIGKILL)
        finally:
            os.close(master)
            if slave is not None:
                os.close(slave)


if __name__ == "__main__":
    unittest.main()
