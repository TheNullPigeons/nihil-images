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
