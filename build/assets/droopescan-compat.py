"""Migrate droopescan's Cement 2 dependency from imp to importlib."""
from pathlib import Path
import sys

cement = next(Path(sys.argv[1]).glob("lib/python*/site-packages/cement"))
for name in ("core/foundation.py", "core/extension.py"):
    path = cement / name
    path.write_text(path.read_text().replace("from imp import reload", "from importlib import reload"))

path = cement / "ext/ext_plugin.py"
text = path.read_text().replace("import imp\n", "import importlib.util\nimport sys\n")
text = text.replace(
    "        f, path, desc = imp.find_module(plugin_name, [plugin_dir])\n"
    "        mod = imp.load_module(plugin_name, f, path, desc)",
    "        spec = importlib.util.spec_from_file_location(plugin_name, full_path)\n"
    "        mod = importlib.util.module_from_spec(spec)\n"
    "        sys.modules[plugin_name] = mod\n"
    "        try:\n"
    "            spec.loader.exec_module(mod)\n"
    "        except BaseException:\n"
    "            sys.modules.pop(plugin_name, None)\n"
    "            raise",
)
path.write_text(text)
