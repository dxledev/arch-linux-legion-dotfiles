#!/usr/bin/python3
import json
import sys
from pathlib import Path

state = json.loads(Path(sys.argv[1]).read_text())
mode = sys.argv[2]
if mode == 'waybar':
    assert set(state['processes']) == {'ward', 'waybar', 'wardnc', 'chromack', 'topdash', 'swayosd-server'}, state
    assert state['qs'] == '' and not state['noctalia'], state
elif mode == 'noctalia':
    assert state['noctalia'] and state['qs'] == '' and state['processes'] == [], state
else:
    assert state['qs'] == mode and not state['noctalia'] and state['processes'] == [], state
