import pandas, luadata, os

SRC_PATH = os.path.abspath(os.path.join(__file__, '..', 'data.tsv'))
DST_PATH = os.path.abspath(os.path.join(__file__, '..\\..\\..\\dat\\MY_RoleStatistics\\data\\serendipity\\zhcn.jx3dat'))

res = []

def serialize(key, val):
	if type(val) == float:
		return int(val)
	if key.startswith('a'):
		return luadata.const(val)
	return val

for _, row in pandas.read_csv(SRC_PATH, sep='\t', encoding="utf-8", skiprows=2).iterrows():
	res.append({k : serialize(k, v)
					for k, v in dict(row).items()
						if pandas.notna(v) and k != 'id' and not k.startswith('Unnamed')})

luadata.write(res, DST_PATH, encoding='gbk', form = True)
