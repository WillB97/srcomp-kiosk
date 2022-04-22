#!/usr/bin/env python3

from __future__ import print_function

import os.path
import textwrap

LIVESTREAM_URL = 'https://www.youtube-nocookie.com/embed/7HNG2bqwXlo'

FILE_NAME = 'pi_macs'
NAME_TEMPLATE = 'pi-{page}-{qual}.srobo'
PAGE_TEMPLATE = 'http://%{{hiera(\'compbox_hostname\')}}/{page}.html{query}'
CONTENT_TEMPLATE = '''# Student Robotics Pi {ident}
---
url: {url}
hostname: {name}
remote_ssh_port: {remote_ssh_port}
'''

def tidy(lines):
    output_lines = []
    for line in lines:
        hash_idx = line.find('#')
        if hash_idx > -1:
            line = line[:hash_idx]

        line = line.strip()
        if line:
            output_lines.append(line)

    return output_lines

def build_url(page):
    if page == 'livestream':
        return LIVESTREAM_URL

    parts = page.split('?')
    if len(parts) == 1:
        return PAGE_TEMPLATE.format(page=page, query='')
    else:
        query = '?' + parts[1]
        return PAGE_TEMPLATE.format(page=parts[0], query=query)

def build_name(ident, page):
    parts = page.split('?')
    if len(parts) == 1:
        return NAME_TEMPLATE.format(page=page, qual=ident)
    else:
        qual = parts[1].replace(',', '')
        return NAME_TEMPLATE.format(page=parts[0], qual=qual)

def build_filename(mac):
    return os.path.join('hieradata', 'node', mac + '.yaml')

def build_port(mac):
    left, right = mac.split(':')[-2:]
    upper, lower = int(left, 16), int(right, 16)
    port = upper * 0xff + lower
    return port


with open(FILE_NAME, 'r') as fh:
    lines = tidy(fh.readlines())

port_to_name = {}

for line in lines:
    ident, mac, page = line.split()
    name = build_name(ident, page)
    url = build_url(page)

    remote_ssh_port = build_port(mac)
    assert remote_ssh_port not in port_to_name
    port_to_name[remote_ssh_port] = name

    fn = build_filename(mac)
    with open(fn, 'w+') as fh:
        fh.write(CONTENT_TEMPLATE.format(
            name=name,
            ident=ident,
            url=url,
            remote_ssh_port=remote_ssh_port,
        ))

with open('pi-ssh-config', mode='w') as f:
    for port, name in port_to_name.items():
        f.write(textwrap.dedent(f'''
            Host {name}
                HostName localhost
                Port {port}
                ProxyJump srcomp.studentrobotics.org
        '''))

with open('pi-names', mode='w') as f:
    print('\n'.join(port_to_name.values()), file=f)
