#!/usr/bin/python3
import json
import os
import sys
from pathlib import Path

root = Path(os.environ['ISLAND_TEST_ROOT'])
path = root / 'processes.json'
state = json.loads(path.read_text()) if path.exists() else {'processes': [], 'qs': '', 'noctalia': False}
name = Path(sys.argv[0]).name
args = sys.argv[1:]
result = 0

def save():
    temporary = path.with_suffix('.tmp')
    temporary.write_text(json.dumps(state))
    temporary.replace(path)

def theme(selected):
    themes = Path(os.environ['THEMES_DIR'])
    temporary = themes / '.current-next'
    temporary.symlink_to(themes / selected)
    temporary.replace(themes / 'current')

if name == 'pgrep':
    result = 0 if args[-1] in state['processes'] else 1
elif name == 'pkill':
    state['processes'] = [entry for entry in state['processes'] if entry != args[-1]]
    save()
elif name == 'kill':
    state['qs'] = ''
    save()
elif name == 'systemctl':
    if 'is-active' in args:
        result = 0 if 'ward' in state['processes'] else 1
    elif 'start' in args:
        state['processes'].append('ward')
        save()
    elif 'stop' in args:
        state['processes'] = [entry for entry in state['processes'] if entry != 'ward']
        save()
elif name == 'qs':
    selected = args[args.index('--path') + 1] if '--path' in args else args[args.index('-p') + 1]
    selected = 'island' if '/island/' in selected else 'caelestia'
    if 'list' in args:
        print(json.dumps([{'pid': int(os.environ['ISLAND_TEST_PID'])}] if state['qs'] == selected else []))
    elif 'ipc' in args:
        print('false' if (root / 'fail-island-health').exists() else 'true')
    else:
        state['qs'] = selected
        save()
elif name == 'noctalia':
    if 'status' in args:
        print(json.dumps({'running': state['noctalia'], 'profile': 'full' if state['noctalia'] else '', 'locked': False}))
    else:
        state['noctalia'] = 'start' in args
        save()
elif name == 'sync':
    if '--describe' in args:
        print(json.dumps({'source': 'custom', 'staticTheme': 'nord'}))
    elif '--cancel' not in args:
        theme('nord')
elif name == 'shell-theme':
    if 'status' in args:
        print(json.dumps({'source': 'system', 'staticTheme': 'bauhaus'}))
    else:
        theme('bauhaus')
elif name == 'island-theme':
    if 'status' in args:
        print(json.dumps({'source': 'system', 'staticTheme': 'dracula'}))
    elif (root / 'fail-island').exists():
        result = 1
    else:
        theme('dracula')
elif name in ['waybar', 'ward', 'wardnc', 'chromack', 'topdash', 'swayosd-server', 'hyprlock']:
    state['processes'].append(name)
    save()
sys.exit(result)
