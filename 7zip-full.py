# -*- coding: utf-8 -*-

import importlib

runner = importlib.import_module('7zip')

if __name__ == '__main__':
    runner.run('full release')
