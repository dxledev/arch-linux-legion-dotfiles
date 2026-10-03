#!/usr/bin/env python3
import json
import os
from pathlib import Path
import subprocess
import tempfile

PLUGIN = Path(__file__).resolve().parents[1]
SCRIPTS = Path(os.environ.get('DESKTOP_SCRIPTS_DIR', str(Path.home() / 'bin')))
IDS = ['dwindle', 'scrolling', 'master', 'monocle', 'lua:grid', 'lua:spiral', 'lua:manual', 'lua:centerstack']
NAMES = ['Dwindle', 'Scrolling', 'Master', 'Monocle', 'Grid', 'Spiral', 'Manual', 'Center-Stack']


def run(*args, env, success=True):
    result = subprocess.run(args, env=env, text=True, capture_output=True)
    assert (result.returncode == 0) == success, result.stderr
    return result.stdout


with tempfile.TemporaryDirectory(prefix='layout-menu-') as directory:
    root = Path(directory)
    hypr = root / 'config/hypr'
    hypr.mkdir(parents=True)
    scripts = root / 'bin'
    scripts.mkdir()
    for name in ['menu-layout', 'lib-hypr-lua']:
        (scripts / name).symlink_to(SCRIPTS / name)
    mock = root / 'hyprctl'
    mock.write_text('#!/usr/bin/env bash\nprintf "%s\\n" "$*" >> "$LAYOUT_TEST_LOG"\n')
    mock.chmod(0o755)
    env = dict(os.environ, DESKTOP_SCRIPTS_DIR=str(scripts), XDG_CONFIG_HOME=str(root / 'config'),
               XDG_STATE_HOME=str(root / 'state'), HYPRCTL_BIN=str(mock),
               LAYOUT_TEST_LOG=str(root / 'runtime.log'), SLEEP_BIN='/usr/bin/false')
    config = hypr / 'decorations.lua'
    animations = hypr / 'animations.lua'
    animations.write_text('animations = {\n enabled = true,\n}\n{ "workspaces", true, 4.9, "overshot", "slide 100%" },\n')
    helper = str(PLUGIN / 'layout-menu')
    for layout in IDS:
        config.write_text('general = {\n layout = "' + layout + '",\n}\n')
        rows = json.loads(run(helper, '--list', env=env))
        assert [row['id'] for row in rows] == IDS
        assert [row['name'] for row in rows] == NAMES
        assert [row['id'] for row in rows if row['current']] == [layout]
    config.write_text('general = {\n layout = "dwindle",\n}\n')
    original = config.read_bytes(), animations.read_bytes()
    run(helper, '--dry-run', 'scrolling', env=env)
    run(helper, '--apply', 'invalid', env=env, success=False)
    assert original == (config.read_bytes(), animations.read_bytes())
    assert not (root / 'runtime.log').exists()
    run(helper, '--apply', 'dwindle', env=env)
    assert not (root / 'runtime.log').exists()
    run(helper, '--apply', 'scrolling', env=env)
    axis = root / 'state/menu-layout/workspace-axis.state'
    assert axis.read_text().strip() == 'horizontal'
    assert 'slidevert' in animations.read_text()
    animations.write_text(animations.read_text().replace('slidevert', 'slide'))
    run(helper, '--apply', 'scrolling', env=env)
    assert 'slidevert' in animations.read_text()
    assert axis.read_text().strip() == 'horizontal'
    run(helper, '--apply', 'lua:centerstack', env=env)
    assert 'lua:centerstack' in config.read_text()
    assert 'slidevert' not in animations.read_text()
    assert not axis.exists()
    config.write_text('general = {\n layout = "unknown",\n}\n')
    before = (root / 'runtime.log').read_bytes()
    run(helper, '--list', env=env, success=False)
    run(helper, '--apply', 'master', env=env, success=False)
    assert (root / 'runtime.log').read_bytes() == before
    config.unlink()
    (hypr / 'decorations.conf').write_text('general {\n layout = lua:grid\n}\n')
    assert json.loads(run(helper, '--list', env=env))[4]['current']

print('Layout helper fixtures passed')
