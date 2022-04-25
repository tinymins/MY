import codecs, pandas, luadata, os

SRC_PATH = os.path.abspath(os.path.join(__file__, '..', 'data.tsv'))
POS_PATH = os.path.abspath(os.path.join(__file__, '..', 'pos.tsv'))
DST_PATH = os.path.abspath(os.path.join(__file__, '..\\..\\..\\..\\MY_RoleStatistics\\data\\serendipity\\zhcn_hd.jx3dat'))

def rowappend(a, p, k, v):
	if not pandas.notna(v) or k == 'id' or k.startswith('Unnamed'):
		return
	if k == 'dwType' or k.startswith('a'):
		pass
	elif k.startswith('dw') or k.startswith('n'):
		v = luadata.serialize(int(v))
	else:
		v = luadata.serialize(v, 'gbk')
	a.append('%s%s = %s,' % (p, k, v))

res = ['return {']

res.append('\t{')
for _, row in pandas.read_csv(SRC_PATH, sep='\t', encoding='utf-8', skiprows=2).iterrows():
	res.append('\t\t{')
	for k, v in dict(row).items():
		rowappend(res, '\t\t\t', k, v)
	res.append('\t\t},')
res.append('\t},')

res.append('\t{')
for _, row in pandas.read_csv(POS_PATH, sep='\t', encoding='utf-8', skiprows=1).iterrows():
	res.append('\t\t{')
	for k, v in dict(row).items():
		rowappend(res, '\t\t\t', k, v)
	res.append('\t\t},')
res.append('\t},')

res.append('}')

with codecs.open(DST_PATH, 'w', 'gbk') as file:
	file.write('\n'.join(res))
