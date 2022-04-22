#!/usr/bin/env python3

import argparse
import logging
import os
import signal
import subprocess
import sys
import time
import yaml

# Parse arguments to get the config file location
FIREFOX_TYPE = 'firefox'
CHROMIUM_TYPE = 'chromium-browser'

DEFAULT_BROWSER_TYPE = FIREFOX_TYPE
DEFAULT_CONFIG  = '/etc/srcomp-kiosk/config.yaml'
DEFAULT_PROFILE = '/opt/srcomp-kiosk/firefox-profile'

BROWSER_TYPES = (FIREFOX_TYPE, CHROMIUM_TYPE)
assert DEFAULT_BROWSER_TYPE in BROWSER_TYPES

logging.basicConfig(
    stream=sys.stdout,
    level=logging.INFO,
    format='%(asctime)s (pid:%(process)d) %(levelname)s:%(message)s',
)
logging.info(
    "Starting kiosk on '%s' from '%s'.",
    os.environ.get('DISPLAY'),
    os.getcwd(),
)

parser = argparse.ArgumentParser(description='srcomp kiosk system')
parser.add_argument(
    '--config',
    dest='config',
    help='Config file location (default: %(default)s)',
    default=DEFAULT_CONFIG,
)
parser.add_argument(
    '--browser-type',
    dest='browser_type',
    help='Browser type to use (default: %(default)s)',
    default=DEFAULT_BROWSER_TYPE,
    choices=BROWSER_TYPES,
)
parser.add_argument(
    '--browser-path',
    dest='browser_path',
    help='Path to the browser to use (defaults to the value of the type choice)',
)
parser.add_argument(
    '--profile',
    dest='profile',
    help="Profile to use for firefox based browsers (default: %(default)s, passed to the browser after '--profile')",
    default=DEFAULT_PROFILE,
)

args = parser.parse_args()

_processes = []
def Popen(*args, **kwargs):
    proc = subprocess.Popen(*args, **kwargs)
    _processes.append(proc)
    return proc

class Kiosk(object):
    def __init__(self, args, loop_end):
        self.configPath = args.config
        self.browser_type = args.browser_type
        self.browser_path = args.browser_path if args.browser_path else self.browser_type
        self.profilePath = args.profile
        self.loop_end = loop_end

    def get_url(self):
        with open(self.configPath) as f:
            return yaml.load(f)['url']

    def get_urls(self):
        oldUrl = None
        while True:
            try:
                url = self.get_url()
            except:
                logging.exception("Failed to get url")
            else:
                if url != oldUrl:
                    yield url
                    oldUrl = url

            self.loop_end()

    def main(self):
        for url in self.get_urls():
            try:
                if self.browser_type == FIREFOX_TYPE:
                    Popen([self.browser_path, "--profile", self.profilePath, url])
                elif self.browser_type == CHROMIUM_TYPE:
                    # Oddly, this option doesn't seem documented, and there is
                    # an '--app=URL' option documented. Testing shows that
                    # '--app' doesn't seem to work, while '--kiosk' does.
                    Popen([self.browser_path, "--kiosk", url])
                else:
                    raise AssertionError("Unexpected browser type {}".format(self.browser_type))
            except:
                logging.exception("Failed to set url to '%s'.", url)

# Graceful exit on SIG_TERM -- ensure that we bring down the browser
# and 'unclutter' too.
def do_exit(*args):
    exit()
signal.signal(signal.SIGTERM, do_exit)

# Disable screensaver

xset_commands = [
    ["xset", "-dpms"],
    ["xset", "s", "off"],
    ["xset", "s", "noblank"],
]

logging.info("Disabling the screensaver")
for command in xset_commands:
    cmd = " ".join(command)
    logging.debug("About to run '%s'.", cmd)
    try:
        subprocess.check_call(command)
    except Exception as e:
        logging.exception("Failed to run '$s'.", cmd)
        print(e)

logging.info("Hiding the mouse")
try:
    unclutter = Popen(["unclutter"])
except Exception as e:
    logging.exception("Unclutter failed")
    raise

def loop_end():
    time.sleep(1)
    assert unclutter.poll() is None, "Unclutter has closed!"

kiosk = Kiosk(args, loop_end)
try:
    kiosk.main()
finally:
    logging.info("Exiting")
    logging.debug("Closing %d child processes.", len(_processes))
    for proc in _processes:
        try:
            if proc.poll() is None:
                proc.terminate()
        except:
            cmd = " ".join(proc.args)
            logging.exception("Failed to send terminate signal to a child process ('%s')", cmd)

    for proc in _processes:
        try:
            proc.wait()
        except:
            cmd = " ".join(proc.args)
            logging.exception("Failed to wait for a child process to end ('%s')", cmd)
