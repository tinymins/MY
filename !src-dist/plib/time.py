# -*- coding: utf-8 -*-
# pip install ntplib
# pip install pypiwin32

import time
from .require import require
from .cmd import run_as_admin

ntplib = require('ntplib')

def get_ntp_time(ntp_server_url):
	"""
	Get NTP server time.
	"""
	ntp_client = ntplib.NTPClient()
	ntp_stats = ntp_client.request(ntp_server_url)
	year = time.strftime('%Y', time.localtime(ntp_stats.tx_time))
	month = time.strftime('%m', time.localtime(ntp_stats.tx_time))
	day = time.strftime('%d', time.localtime(ntp_stats.tx_time))
	hour = time.strftime('%H', time.localtime(ntp_stats.tx_time))
	minute = time.strftime('%M', time.localtime(ntp_stats.tx_time))
	second = time.strftime('%S', time.localtime(ntp_stats.tx_time))
	return year, month, day, hour, minute, second

def set_system_time(year, month, day, hour, minute, second):
	"""
	Set system time
	"""
	run_as_admin('date {}-{}-{}'.format(month, day, year))
	run_as_admin('time {}:{}:{}'.format(hour, minute, second))

def sync_ntp_time(ntp_server_url='ntp5.aliyun.com'):
	year, month, day, hour, minute, second = get_ntp_time(ntp_server_url)
	set_system_time(year, month, day, hour, minute, second)
	print('System time has been synchronized with `{}` values "{}/{}/{} {}:{}:{}"'.format(ntp_server_url, year, month, day, hour, minute, second))
