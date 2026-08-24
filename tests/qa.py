from pathlib import Path
import re,sys
root=Path(__file__).resolve().parents[1];docs=root/'docs'
errors=[]
required=['index.html','about.html','services.html','gallery.html','faq.html','contact.html','privacy.html','terms.html','assets/css/site.css','assets/js/site.js','assets/images/brand/logo.png','assets/images/brand/favicon.png']
for r in required:
    if not (docs/r).exists(): errors.append(f'Missing {r}')
for p in docs.rglob('*.html'):
    t=p.read_text(encoding='utf-8')
    if 'noindex,nofollow' not in t: errors.append(f'No noindex in {p.name}')
    low=t.lower()
    # customer-facing process-language bans
    banned=['supplied material','uploaded images','source material','our research','client-provided','source of truth','prototype','mockup','demo website','private review']
    for b in banned:
        if b in low: errors.append(f'Forbidden wording {b!r} in {p.name}')
    if re.search(r'[A-Za-z]:\\|/mnt/data|localhost:',t): errors.append(f'Absolute/local path in {p.name}')
    for m in re.findall(r'(?:src|href)="([^"]+)"',t):
        if m.startswith(('http:','https:','tel:','mailto:','#','javascript:')): continue
        target=(p.parent/m).resolve()
        if not target.exists(): errors.append(f'Broken local reference {m} in {p.name}')
if errors:
    print('QA FAIL');[print(' -',e) for e in errors];sys.exit(1)
print('QA PASS')
