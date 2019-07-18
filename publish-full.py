# -*- coding: utf-8 -*-

import importlib

runner = importlib.import_module('publish')

if __name__ == '__main__':
    runner.run('full release')
