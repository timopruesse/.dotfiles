"""Agent launchers must use the caller's workspace, never UI focus."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

SCRIPTS = Path(__file__).resolve().parents[1] / 'home/.config/herdr/scripts'


class HerdrSpaceTests(unittest.TestCase):
    def test_launcher_follows_live_caller_space(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            for source in SCRIPTS.glob('coding_agent*'):
                shutil.copy(source, root)
            fake = root / 'herdr'
            fake.write_text('''#!/usr/bin/env python3
import json, os, sys
args = sys.argv[1:]
with open(os.environ['CALL_LOG'], 'a') as log:
    log.write(json.dumps(args) + '\\n')
if args[:2] == ['pane', 'current']:
    if os.environ.get('FAIL_CONTEXT') or not os.environ.get('HERDR_PANE_ID'):
        sys.exit(1)
    print(json.dumps({'result': {'pane': {'workspace_id': 'w2', 'pane_id': 'w2:p3'}}}))
elif args[:2] in (['tab', 'create'], ['pane', 'split']):
    if args[0] == 'tab':
        space = args[args.index('--workspace') + 1] if '--workspace' in args else 'w1'
    else:
        space = 'w2' if '--current' in args or 'w2:p3' in args else 'w1'
    print(json.dumps({'result': {'root_pane': {'pane_id': space + ':p4'}, 'pane': {'pane_id': space + ':p4'}, 'tab': {'tab_id': space + ':t4'}}}))
else:
    print('{}')
''')
            fake.chmod(0o755)
            env = {**os.environ, 'PATH': str(root) + ':' + os.environ['PATH'],
                   'HERDR_ENV': '1', 'HERDR_PANE_ID': 'w0:p3',
                   'HERDR_WORKSPACE_ID': 'w0', 'CALL_LOG': str(root / 'calls')}
            for layout in ('tab', 'right', 'down'):
                with self.subTest(layout=layout):
                    command = [str(root / 'coding_agent_herdr.sh'), layout, '--pi', '--', '--literal']
                    result = subprocess.run(command, env=env, capture_output=True, text=True)
                    self.assertEqual(result.returncode, 0, result.stderr)
                    self.assertIn('w2:p4', result.stdout)
                    calls = [json.loads(line) for line in (root / 'calls').read_text().splitlines()]
                    runs = [call for call in calls if call[:2] == ['pane', 'run']]
                    self.assertEqual(runs[-1], ['pane', 'run', 'w2:p4',
                                     str(root / 'coding_agent_launch.sh'), '--pi', '--', '--literal'])
                    for unavailable in ({'HERDR_PANE_ID': ''}, {'FAIL_CONTEXT': '1'}):
                        (root / 'calls').write_text('')
                        failed = subprocess.run(command, env={**env, **unavailable},
                                                capture_output=True, text=True)
                        self.assertNotEqual(failed.returncode, 0)
                        calls = [json.loads(line) for line in (root / 'calls').read_text().splitlines()]
                        self.assertFalse(any(call[:2] in (['tab', 'create'], ['pane', 'split']) for call in calls))


if __name__ == '__main__':
    unittest.main()
