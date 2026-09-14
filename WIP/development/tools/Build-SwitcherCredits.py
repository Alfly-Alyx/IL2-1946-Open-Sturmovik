#!/usr/bin/env python3
"""Embed the credits source in the switcher, with no Markdown runtime dependency.

Run from any directory: python tools/Build-SwitcherCredits.py
Use --check to verify that the embedded page matches its Markdown source.
Supported source syntax: headings, paragraphs, tables, links, bold and escaped pipes.
Local documentation links remain readable text, with the original path in a tooltip.
"""

import argparse
import html
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / '_Documentations' / 'Mods and Tools' / 'Credits - Open Sturmovik.md'
SWITCHER = ROOT / 'Open_Sturmovik_Switcher.bat'
TOKEN = re.compile(r'\[([^\]]+)\]\((?:<([^>]+)>|([^\s)]+))\)|\*\*(.+?)\*\*')


def escaped(text):
    return html.escape(text.replace(r'\|', '|'), quote=True).encode('ascii', 'xmlcharrefreplace').decode('ascii')


def inline(text):
    result = []
    position = 0
    for token in TOKEN.finditer(text):
        result.append(escaped(text[position:token.start()]))
        if token.group(4) is not None:
            result.append('<strong>' + inline(token.group(4)) + '</strong>')
        else:
            label = inline(token.group(1))
            target = token.group(2) or token.group(3)
            if re.fullmatch(r'https?://[A-Za-z0-9.-]+(?::[0-9]+)?/[^\s<>"\x27]*', target):
                result.append('<a href="' + escaped(target) + '" onclick="return openCreditLink(this.href)">' + label + '</a>')
            else:
                result.append('<span class="credits-reference" title="Documentation : ' + escaped(target) + '">' + label + '</span>')
        position = token.end()
    result.append(escaped(text[position:]))
    return ''.join(result)


def cells(line):
    return [value.strip() for value in re.split(r'(?<!\\)\|', line.strip().strip('|'))]


def render(source):
    lines = source.splitlines()
    body, navigation = [], []
    section = 0
    title = None
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        if not line:
            i += 1
            continue
        if line.startswith('# '):
            if title is not None:
                raise ValueError('The credits source must have only one title.')
            title = inline(line[2:])
            i += 1
            continue
        if line.startswith('## '):
            section += 1
            if section > 1:
                body.append('</div>')
            target = 'credits-section-' + str(section)
            body.append('<div class="credits-section" id="' + target + '">')
            body.append('<h2>' + inline(line[3:]) + '</h2>')
            navigation.append('<option value="' + target + '">' + escaped(line[3:]) + '</option>')
            i += 1
            continue
        if line.startswith('|'):
            headers = cells(line)
            i += 1
            if i >= len(lines) or not all(re.fullmatch(r':?-+:?', cell) for cell in cells(lines[i])):
                raise ValueError('Missing table separator after: ' + line)
            i += 1
            body.append('<table class="credits-table cols-' + str(len(headers)) + '">')
            body.append('<thead><tr>' + ''.join('<th scope="col">' + inline(cell) + '</th>' for cell in headers) + '</tr></thead>')
            body.append('<tbody>')
            while i < len(lines) and lines[i].strip().startswith('|'):
                values = cells(lines[i])
                if len(values) != len(headers):
                    raise ValueError('Wrong number of table cells: ' + lines[i])
                body.append('<tr>' + ''.join('<td' + (' class="credits-author"' if n == 1 else '') + '>' + inline(value) + '</td>' for n, value in enumerate(values)) + '</tr>')
                i += 1
            body.append('</tbody></table>')
            continue
        paragraph = [line]
        i += 1
        while i < len(lines) and lines[i].strip() and not lines[i].lstrip().startswith(('# ', '## ', '|')):
            paragraph.append(lines[i].strip())
            i += 1
        body.append('<p>' + inline(' '.join(paragraph)) + '</p>')
    if section:
        body.append('</div>')
    if title is None:
        raise ValueError('Missing credits title.')
    return {'TITLE': title, 'NAVIGATION': '\n'.join(navigation), 'CONTENT': '\n'.join(body)}


def update_block(text, name, content):
    start = '<!-- BEGIN GENERATED CREDITS ' + name + ' -->'
    end = '<!-- END GENERATED CREDITS ' + name + ' -->'
    if text.count(start) != 1 or text.count(end) != 1:
        raise ValueError('Missing or duplicated switcher block: ' + name)
    begin = text.index(start) + len(start)
    finish = text.index(end, begin)
    return text[:begin] + '\n' + content + '\n' + text[finish:]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true', help='Fail if the embedded page needs regeneration.')
    args = parser.parse_args()
    original = SWITCHER.read_bytes()
    text = original.decode('utf-8').replace('\r\n', '\n')
    for name, content in render(SOURCE.read_text(encoding='utf-8-sig')).items():
        text = update_block(text, name, content)
    rendered = text.replace('\n', '\r\n').encode('utf-8')
    if args.check:
        if rendered != original:
            raise SystemExit('Credits page is stale. Run python tools/Build-SwitcherCredits.py')
        print('Credits page matches its Markdown source; UTF-8 without BOM, CRLF.')
    else:
        SWITCHER.write_bytes(rendered)
        print('Credits page embedded from ' + str(SOURCE.relative_to(ROOT)))


if __name__ == '__main__':
    main()