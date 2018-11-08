#!/usr/bin/env python
# -*- coding: utf-8 -*-
from l_converter import *

def zhcn2zhtw(sentence):
    '''
    将sentence中的简体字转为繁体字
    :param sentence: 待转换的句子
    :return: 将句子中简体字转换为繁体字之后的句子
    '''
    return Converter('zh-hant').convert(sentence)

def zhtw2zhcn(sentence):
    '''
    将sentence中的繁体字转为简体字
    :param sentence: 待转换的句子
    :return: 将句子中繁体字转换为简体字之后的句子
    '''
    return Converter('zh-hans').convert(sentence)
