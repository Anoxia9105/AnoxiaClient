import json

files = ['assets/i18n/zh.json', 'assets/i18n/en.json', 'assets/i18n/ja.json']
out = []
for f in files:
    try:
        with open(f, encoding='utf-8-sig') as fp:
            data = json.load(fp)
        out.append('%s OK: %s' % (f, data.get('call_n_in_call')))
    except Exception as e:
        out.append('%s INVALID: %s' % (f, e))

with open('i18ncheck.tmp', 'w', encoding='utf-8') as fp:
    fp.write('\n'.join(out))
