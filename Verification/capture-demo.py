# Usage: python3 Verification/capture-demo.py UUID iPhone|iPad APP_PATH
import subprocess, time, signal, sys
from pathlib import Path
sim, kind, app = sys.argv[1:]
root = Path(__file__).resolve().parents[1] / 'Demo'
def run(*args):
    return subprocess.run(['xcrun', 'simctl', *args], check=True, capture_output=True, text=True)
def stop():
    subprocess.run(['xcrun', 'simctl', 'terminate', sim, 'test.iosHW6'], capture_output=True)
def shot(name):
    target = root/'images'/f'{kind}-{name}.png'
    for attempt in range(40):
        run('io', sim, 'screenshot', str(target))
        if target.stat().st_size > 110000:
            return
        time.sleep(3)
    raise RuntimeError('Launch screen did not finish: ' + name)
run('bootstatus', sim, '-b')
run('install', sim, app)
run('status_bar', sim, 'override', '--time', '9:41', '--batteryState', 'charged', '--batteryLevel', '100')
for name, args in [('home', []), ('schedule', ['-schedule']), ('review', ['-review'])]:
    stop(); run('launch', sim, 'test.iosHW6', *args); time.sleep(4); shot(name)
    print(kind, name, flush=True)
stop()
container = Path(run('get_app_container', sim, 'test.iosHW6', 'data').stdout.strip()) / 'Documents'
container.mkdir(exist_ok=True)
for name in ['demo-phase.txt', 'demo-go', 'demo-confirm']:
    (container/name).unlink(missing_ok=True)
run('launch', sim, 'test.iosHW6', '-demo')
def wait_phase(expected):
    for attempt in range(240):
        marker = container/'demo-phase.txt'
        if marker.exists() and marker.read_text() == expected:
            return
        time.sleep(1)
    raise RuntimeError('Demo did not reach ' + expected)
wait_phase('ready')
time.sleep(2)
video = subprocess.Popen(['xcrun', 'simctl', 'io', sim, 'recordVideo', '--codec=h264', '--force', str(root/f'TeaAtelier-{kind}-demo.mp4')], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
time.sleep(2)
(container/'demo-go').write_text('start')
wait_phase('confirmation'); time.sleep(1); shot('confirmation')
(container/'demo-confirm').write_text('confirmed')
wait_phase('history'); time.sleep(2); shot('history')
time.sleep(3)
video.send_signal(signal.SIGINT)
video.communicate(timeout=30)
stop(); run('launch', sim, 'test.iosHW6')
print(kind, 'complete', flush=True)
