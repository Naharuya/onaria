import collections, importlib.util, struct, unittest
from pathlib import Path
spec=importlib.util.spec_from_file_location('retention',Path(__file__).parents[1]/'scripts/onaria_legacy_journal_retention.py'); m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
def row(unit=b'onaria-backend.service',timestamp=b'10',message=b'hello'):
 return b'__REALTIME_TIMESTAMP='+timestamp+b'\n_SYSTEMD_UNIT='+unit+b'\nMESSAGE\n'+struct.pack('<Q',len(message))+message+b'\n\n'
class RetentionTests(unittest.TestCase):
 def test_removes_only_aged_onaria(self):
  data=row()+row(b'beavers.service')+row(timestamp=b'30')
  kept,expected,removed,total=m.filter_export(data,20)
  self.assertEqual((removed,total),(1,3)); self.assertEqual(kept,row(b'beavers.service')+row(timestamp=b'30'));self.assertEqual(sum(expected.values()),2)
 def test_binary_and_duplicate_fields_preserved(self):
  data=row(b'beavers.service',message=b'first\n\x00second').replace(b'\n\n',b'\nEXTRA=one\nEXTRA=two\n\n')
  kept,_,removed,_=m.filter_export(data,20);self.assertEqual(kept,data);self.assertEqual(removed,0)
 def test_cutoff_boundary_retained(self):
  kept,_,removed,_=m.filter_export(row(timestamp=b'20'),20);self.assertTrue(kept);self.assertEqual(removed,0)
 def test_ambiguous_unit_retained(self):
  data=row().replace(b'\nMESSAGE',b'\n_SYSTEMD_UNIT=beavers.service\nMESSAGE');self.assertEqual(m.filter_export(data,20)[2],0)
 def test_missing_or_duplicate_timestamp_rejected(self):
  for data in [row(timestamp=b'invalid'),row().replace(b'\n_SYSTEMD_UNIT',b'\n__REALTIME_TIMESTAMP=11\n_SYSTEMD_UNIT')]:
   with self.assertRaises(ValueError):m.filter_export(data,20)
 def test_truncated_binary_rejected(self):
  with self.assertRaises(ValueError):list(m.entries(row()[:-4]))
 def test_address_changes_only_not_content_changes(self):
  fields=list(m.entries(row(b'beavers.service')))[0][0]
  self.assertEqual(m.fingerprint(fields+[(b'__CURSOR',b'old')]),m.fingerprint(fields+[(b'__CURSOR',b'new')]))
  self.assertNotEqual(m.fingerprint(fields),m.fingerprint(fields+[(b'EXTRA',b'changed')]))
if __name__=='__main__':unittest.main()
