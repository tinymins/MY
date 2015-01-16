# -*- coding: UTF-8 -*-
import subprocess
retval = subprocess.call([
    "python", "convert-info.py", "zhcn"
], 0, None, None, None, None)

import os
os.system('pause')
