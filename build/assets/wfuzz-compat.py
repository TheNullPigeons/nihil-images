"""Use importlib for wfuzz's Python plugin loader on Python 3.12+."""
from pathlib import Path
import sys

path = next(Path(sys.argv[1]).glob(
    "lib/python*/site-packages/wfuzz/externals/moduleman/loader.py"
))
text = path.read_text().replace("import imp\n", "import importlib.util\nimport sys\n")
text = text.replace(
    "            exten_file, filename, description = imp.find_module(fn, [dirname])\n"
    "            module = imp.load_module(fn, exten_file, filename, description)",
    "            filename = os.path.join(dirname, filename)\n"
    "            spec = importlib.util.spec_from_file_location(fn, filename)\n"
    "            module = importlib.util.module_from_spec(spec)\n"
    "            sys.modules[fn] = module\n"
    "            try:\n"
    "                spec.loader.exec_module(module)\n"
    "            except BaseException:\n"
    "                sys.modules.pop(fn, None)\n"
    "                module = None\n"
    "                raise",
)
path.write_text(text)
