# -*- coding: UTF-8 -*-
import subprocess
retval = subprocess.call([
    "python", "convert-info.py", "zhtw"
], 0, None, None, None, None)

import os
os.system('pause')
