import pandas, luadata, os

SRC_PATH = os.path.abspath(os.path.join(__file__, '..', 'data.tsv'))
POS_PATH = os.path.abspath(os.path.join(__file__, '..', 'pos.tsv'))
DST_PATH = os.path.abspath(os.path.join(__file__, '..\\..\\..\\dat\\MY_RoleStatistics\\data\\serendipity\\zhcn.jx3dat'))

res = []

def serialize(key, val):
	if type(val) == float:
		return int(val)
	if key == 'dwType' or key.startswith('a'):
		return luadata.const(val)
	return val

data = []
for _, row in pandas.read_csv(SRC_PATH, sep='\t', encoding="utf-8", skiprows=2).iterrows():
	data.append({k : serialize(k, v)
					for k, v in dict(row).items()
						if pandas.notna(v) and k != 'id' and not k.startswith('Unnamed')})
res.append(data)


pos = []
for _, row in pandas.read_csv(POS_PATH, sep='\t', encoding="utf-8", skiprows=1).iterrows():
	pos.append({k : serialize(k, v)
					for k, v in dict(row).items()
						if pandas.notna(v) and k != 'id' and not k.startswith('Unnamed')})
res.append(pos)

luadata.write(res, DST_PATH, encoding='gbk', form = True)
