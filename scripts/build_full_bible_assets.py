import json,xml.etree.ElementTree as ET,pathlib,hashlib
import argparse
parser=argparse.ArgumentParser()
parser.add_argument('source_directory', type=pathlib.Path)
args=parser.parse_args()
root=pathlib.Path(__file__).resolve().parent.parent
src=args.source_directory
ko='창세기 출애굽기 레위기 민수기 신명기 여호수아 사사기 룻기 사무엘상 사무엘하 열왕기상 열왕기하 역대상 역대하 에스라 느헤미야 에스더 욥기 시편 잠언 전도서 아가 이사야 예레미야 예레미야애가 에스겔 다니엘 호세아 요엘 아모스 오바댜 요나 미가 나훔 하박국 스바냐 학개 스가랴 말라기 마태복음 마가복음 누가복음 요한복음 사도행전 로마서 고린도전서 고린도후서 갈라디아서 에베소서 빌립보서 골로새서 데살로니가전서 데살로니가후서 디모데전서 디모데후서 디도서 빌레몬서 히브리서 야고보서 베드로전서 베드로후서 요한일서 요한이서 요한삼서 유다서 요한계시록'.split()
# These inputs are pinned to the reviewed public distribution.
expected = {'korrv-complete.xml': '71a6994495a64d5c6962e65df711c2abeb81b61d49ccea9fb4f88077554e40b9', 'web-complete.xml': 'ac0fe5d87ef7c192afa199eaf05a17e172c199e9b9776624daf89614224864f3'}
for name, digest in expected.items():
 if hashlib.sha256((src/name).read_bytes()).hexdigest() != digest:
  raise ValueError('Unreviewed Bible source: '+name)
k=ET.parse(src/'korrv-complete.xml').getroot(); books=k.findall('BIBLEBOOK')
en=[b.attrib['bname'] for b in books]
for lang,file in [('ko','korrv-complete.xml'),('en','web-complete.xml')]:
 t=ET.parse(src/file).getroot(); rows=[]
 if lang=='ko':
  for i,b in enumerate(t.findall('BIBLEBOOK')):
   for c in b.findall('CHAPTER'):
    for v in c.findall('VERS'): rows.append([i,int(c.attrib['cnumber']),int(v.attrib['vnumber']),''.join(v.itertext()).strip()])
 else:
  codes=list(dict.fromkeys(v.attrib['b'] for v in t.findall('v')))
  assert len(codes)==66
  for v in t.findall('v'): rows.append([codes.index(v.attrib['b']),int(v.attrib['c']),int(v.attrib['v']),''.join(v.itertext()).strip()])
 assert len(set((r[0],r[1],r[2]) for r in rows))==len(rows)
 assert len(set((r[0],r[1]) for r in rows))==1189
 data={'edition':'개역한글 · 공개 배포본' if lang=='ko' else 'World English Bible','source':'Zefania KorRV (1952/1961)' if lang=='ko' else 'eBible.org engwebp','sourceSha256':hashlib.sha256((src/file).read_bytes()).hexdigest(),'books':ko if lang=='ko' else en,'verses':rows}
 (root/f'assets/data/full_bible_{lang}.json').write_text(json.dumps(data,ensure_ascii=False,separators=(',',':'))+'\n')
 print(lang,len(rows))
