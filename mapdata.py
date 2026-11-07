import json,math
g=json.load(open('geo.json'))
def dp(pts,tol):
    if len(pts)<3: return pts
    a,b=pts[0],pts[-1]
    dx,dy=b[0]-a[0],b[1]-a[1]; L=math.hypot(dx,dy) or 1e-12
    m,idx=0,0
    for i in range(1,len(pts)-1):
        d=abs(dy*(pts[i][0]-a[0])-dx*(pts[i][1]-a[1]))/L
        if d>m: m,idx=d,i
    if m>tol: return dp(pts[:idx+1],tol)[:-1]+dp(pts[idx:],tol)
    return [a,b]
lines=[]
names=[('occ','Occupation perimeter'),('rus','Russian perimeter'),('esc','Escape Route North (PÓŁ)'),('esc','Escape Route East (WSC)'),('esc','Escape Route South (POŁ)'),('esc','Escape Route Far East (ZAC)')]
li=0
for f in g['features']:
    if f['geometry']['type']=='LineString':
        c=[[round(x,4),round(y,4)] for x,y in dp(f['geometry']['coordinates'],0.0005)]
        lines.append(dict(k=names[li][0],n=names[li][1],c=c)); li+=1
# points: (kind, code, name, lon, lat, loc id or '', note)
P=[
('out','Z1','Żerań, OP-Żerań',20.9964,52.2926,'loc-001','Main survivor base'),
('out','Z2','Zoo, OP-Zoo',21.0255,52.2573,'loc-002','Key survivor supply node'),
('out','S1','Brodno, hospital',21.1071,52.2984,'loc-003','Main survivor medical facility'),
('out','P1','Praski',21.0310,52.2483,'loc-004','The Docks and market'),
('out','R1','Rynek, Grochów',21.0491,52.2553,'loc-005','Main community zone'),
('out','G1','Gocławek',21.1246,52.2357,'loc-006','Start of the east escape route'),
('out','A1','Mała Afryka',21.0660,52.2234,'loc-007','Vistula navigation hub'),
('out','C1','Czerniaków',21.0478,52.2221,'loc-008','West bank operational hub'),
('out','SK','Siekierki',21.0870,52.2072,'loc-009','Food production zone'),
('out','L1','Las',21.1145,52.1982,'loc-010','Infiltration and exfiltration hub'),
('out','P2','Przyloty',21.1711,52.1456,'loc-011','Main arrival hub'),
('out','P3','Pałac, Wilanów',21.0897,52.1653,'loc-012','Southernmost outpost'),
('out','F1','Filtry',21.0080,52.2206,'loc-013','Westernmost outpost, water filtration'),
('node','EN','Route node, Żerań North',20.9924,52.2952,'loc-027','Escape route node'),
('node','EN','Route node, Anin Junction',21.1272,52.2339,'loc-027','Escape route node'),
('node','EN','Route node, Gocławek South',21.1114,52.1977,'loc-027','Escape route node'),
('node','EN','Route node, Rembertów East',21.1727,52.2010,'loc-027','Escape route node'),
('gate','SG','South Gate, Piaseczno',21.0259,52.0778,'loc-027','Gate at the end of the south route'),
('gate','EG','East Gate, Far Corridor',21.4860,52.0677,'loc-027','Gate at the end of the far east route'),
('gate','EG','East Gate, Freedom Road',21.5547,52.2600,'loc-027','Gate at the end of the east route'),
('gate','NG','North Gate, Jabłonna',21.0093,52.4498,'loc-027','Gate at the end of the north route'),
('kos','K','Kościuszko group, Łomianki',20.9618,52.3354,'','Unverified marker, not in the manuscript'),
# occupier positions: approximate, taken from real-world sites
('rus','C','The Citadel',20.9990,52.2650,'loc-015','Approximate position'),
('rus','PKiN','Palace of Culture and Science',21.0060,52.2317,'loc-016','Approximate position'),
('rus','OT','Old Town and Royal Castle',21.0122,52.2497,'loc-017','Approximate position'),
('rus','SG','Saxon Garden and Łazienki',21.0357,52.2150,'loc-018','Approximate position'),
('rus','SZ','Szucha and Pawiak',21.0236,52.2188,'loc-019','Approximate position'),
('rus','SP1','SP-1, Marymont',20.9752,52.2745,'loc-021','Screening point, approximate position'),
('rus','SP2','SP-2, Torwar',21.0376,52.2183,'loc-022','Screening point, approximate position'),
('rus','SP3','SP-3, Służewiec',20.9945,52.1810,'loc-023','Screening point, approximate position'),
('rus','OK','Okęcie',20.9671,52.1657,'loc-025','Approximate position'),
]
out=dict(lines=lines,pts=[dict(k=p[0],c=p[1],n=p[2],x=p[3],y=p[4],e=p[5],t=p[6]) for p in P])
json.dump(out,open('site/map.json','w'),ensure_ascii=False,separators=(',',':'))
print(sum(len(l['c']) for l in lines), len(open('site/map.json').read()))
