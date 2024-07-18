# -*- coding: utf-8 -*-

import sys
import importlib


def require(name, installer=None):
    if installer is None:
        installer = name
    try:
        return importlib.import_module(name)
    except ImportError:
        sys.exit(
            "Statement `import %s` failed, run command `python -m pip install %s` to install it."
            % (name, installer)
        )
