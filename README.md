Nihil is a minimal offensive environment for security experts, hackers, and students. It provides ready-to-use Docker images and a CLI to spin up a lab without dealing with base distributions or manual installs. It is transparent, modular, and built for real work.

Want to know more? Visit the project website.

## Getting started

Install Nihil from the getting started guide.

The project documentation for images, CLI, and usage is available on the documentation site.

## Third-party licensing

Nihil container images include certain code from Exegol released under GPLv3 before 5 June 2025, as well as other third-party source code. See the [Exegol license](https://github.com/ThePorgs/Exegol/blob/master/LICENSE.md) for details.

## Tool selection and installers

`build/config/tools.json` is the catalogue used by the selector, installation,
and healthcheck. Each entry declares its provider explicitly:

```json
{
    "name": "wesng",
    "cmd": "wes",
    "description": "Windows Exploit Suggester NG",
    "installer": "install_wes"
}
```

The optional `build/config/tool-selection.json` contains `enabled_tools` using
catalogue names. Without a selection, all catalogue tools are enabled; legacy
`disabled_tools` lists remain supported. Core tools are mandatory.

Each module calls `install_selected_tools "mod_name"` after its prerequisites.
Providers run in catalogue order, once per module even when several selected
entries share an installer (for example John and its converters). A selected
command can therefore bring other commands from the same package. Providers
call their dependencies directly; dependencies are not filtered independently.
Keep module preparation, aliases, and error handling around the dispatcher.

Every entry needs an existing Bash installer. Invalid JSON, unknown selected
names, and missing installers fail before tool installation. There is no name
inference or runtime replacement of Bash functions. Variant builds retain only
their modules and corresponding saved selection inside the resulting image.

Run the selection regression tests without installing packages:

```bash
python3 -m unittest discover -s tests -v
```

## Building with tool failures

Builds stop on errors by default. To keep building after failures of non-core
tool installers, pass `--build-arg NIHIL_AUDIT=1` to Docker, or use the CLI:

```bash
nihil build full --source . --allow-tool-failures
nihil image build full --allow-tool-failures --wait
```

Manual GitHub Actions builds expose the same `allow_tool_failures` checkbox.
Each non-core installer runs in a subshell with error checking enabled; a failure
ends that installer and the build continues with the next one. Failed installers
and missing tools are listed in the logs and retained in the image at
`/opt/nihil/build/config/build-failures.log`. The healthcheck still checks selected
commands and paths, including tools whose installer failed.

Base system setup, core tools, invalid configuration, and final cleanup remain
blocking. This replaces the old `NIHIL_AUDIT` behaviour that ignored whole-step
errors. Some installers already handle errors internally; command/path checks
cannot guarantee that a tool is fully functional.

Base setup initializes pacman's local signing key and loads the bundled Arch and
Chaotic-AUR keys before installing tools. The initial Chaotic-AUR signing-key
fetch uses HTTPS with three attempts, each limited to 60 seconds plus a 5-second
termination grace period. Package-manager errors remain visible in build logs.
