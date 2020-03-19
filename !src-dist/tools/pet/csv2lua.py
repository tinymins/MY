import pandas, luadata

PATH = 'Pet.tsv'

res = []

def serialize(key, val):
	if type(val) == float:
		return int(val)
	if key.startswith('a'):
		return luadata.const(val)
	return val

for _, row in pandas.read_csv(PATH, sep='\t', encoding="utf-8", skiprows=2).iterrows():
	res.append({k : serialize(k, v)
					for k, v in dict(row).items()
						if pandas.notna(v) and k != 'id' and not k.startswith('Unnamed')})

luadata.write(res, 'Pet.lua', encoding='gbk', form = True)