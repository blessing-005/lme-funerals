from pathlib import Path
import json,re,sys
root=Path(__file__).resolve().parents[1]; site=root/'docs'
required=['index.html','contact.html','assets/css/styles.css','assets/js/site.js','favicon.svg','favicon.ico','apple-touch-icon.png']
errors=[f'missing {x}' for x in required if not (site/x).exists()]
for f in site.rglob('*.html'):
 s=f.read_text(encoding='utf-8')
 if 'noindex,nofollow' not in s: errors.append(f'{f.name}: review robots missing')
 for attr in re.findall(r'(?:src|href)="([^"]+)"',s):
  if attr.startswith(('http:','https:','mailto:','tel:','#','data:')): continue
  target=(f.parent/attr.split('?',1)[0].split('#',1)[0]).resolve()
  if attr and not target.exists(): errors.append(f'{f.name}: broken path {attr}')
 if 'supplied material' in s.lower() or 'prototype' in s.lower() or 'mockup' in s.lower(): errors.append(f'{f.name}: internal wording')
result={'project':root.name,'status':'PASS' if not errors else 'FAIL','errors':errors}
(root/'qa').mkdir(exist_ok=True);(root/'qa'/'QA_RESULTS.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result,indent=2));sys.exit(1 if errors else 0)
