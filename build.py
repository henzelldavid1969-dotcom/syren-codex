import re, json, sys
sys.path.insert(0,'site')
from hand import LOC, OBJ, LOR
T = {'LOC':('Locations','SYNC_PATH'),'CHR':('Characters','PROB_VAL_0.9'),'OBJ':('Objects','FLUX_LOCK_09'),'LOR':('Lore','ION_PATH')}
data=[]
def mk(t,n,name,mark,grade,summary,entry,full=None):
    d=dict(id=f"{t.lower()}-{n}",ref=f"SYNPTCL/{t}/{n}",type=t,name=name,mark=mark,grade=grade,summary=summary,entry=entry,appears="",reliability="",xrefs="",status="",full=bool(full))
    if full: d.update(full)
    data.append(d)
for n,name,mark,g,s,e in LOC: mk('LOC',n,name,mark,g,s,e)
for n,name,mark,g,s,e in OBJ: mk('OBJ',n,name,mark,g,s,e)
for n,name,mark,g,s,e in LOR: mk('LOR',n,name,mark,g,s,e)
txt=open('characters.md',encoding='utf8').read()
for sec in re.split(r'\n## ',txt)[1:]:
    rows=dict(re.findall(r'^\| ([^|]+?) \| (.*) \|$',sec,re.M))
    ref=rows['Reference']; n=ref.split('/')[-1]
    cat=rows['Category']; sub=cat.split('/')[-1].strip()
    rel=rows['Reliability']; m=re.match(r'([CEU])\b',rel); g=m.group(1) if m else ''
    mk('CHR',n,rows['Name'],sub,g,rows['Summary'],rows['Entry'],full=dict(appears=rows['Appears in'],reliability=rel,xrefs=rows['Cross-references'],status=rows['Status']))
data.sort(key=lambda d:(['LOC','CHR','OBJ','LOR'].index(d['type']),d['ref']))
meta={k:{'label':v[0],'mark':v[1]} for k,v in T.items()}
media=json.load(open('site/media.json'))
for d in data:
    if d['id'] in media: d['media']=media[d['id']]
mp=open('site/map.json',encoding='utf8').read()
html=open('site/template.html',encoding='utf8').read().replace('/*MAP*/',mp)
html=html.replace('/*DATA*/',json.dumps(data,ensure_ascii=False)).replace('/*META*/',json.dumps(meta,ensure_ascii=False))
open('site/codex.html','w',encoding='utf8').write(html)
print(len(data),len(html))
