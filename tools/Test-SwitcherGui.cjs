// Tests the JavaScript embedded in the BAT with an inert DOM. No Windows UI,
// ActiveX, game or capture process can be started by this test.
'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const root = path.resolve(__dirname, '..');
const batch = fs.readFileSync(path.join(root, 'Open_Sturmovik_Switcher.bat'), 'utf8');
const utilityManifest = JSON.parse(fs.readFileSync(path.join(root, 'manifests', 'utilities-v1.15.json'), 'utf8'));
const installer = fs.readFileSync(path.join(root, 'installer', 'Open_Sturmovik_Update_1.15.iss'), 'utf8');
const marker = '### OPEN_STURMOVIK_GUI ###';
const markerAt = batch.indexOf(marker);
assert.notEqual(markerAt, -1);
const html = batch.slice(batch.indexOf('\n', markerAt) + 1);
assert.match(batch, /Open_Sturmovik_Switcher_Background__Pacific_Fighters_Retail\.png/);
assert.match(html, /url\("OpenSturmovikSwitcher-v115-background\.png"\) center center no-repeat/);
assert.match(html, /guiBackgroundTemp/);
assert.match(html, /font-family:"Trebuchet MS",Tahoma,Arial,sans-serif/);
assert.match(html, /border:4px ridge #89938e/);
assert.match(html, /icon="OpenSturmovikSwitcher-v115\.ico"/);
assert.match(html, /width:820px; height:598px/);
assert.match(html, /\.left \{ left:30px; width:380px/);
assert.match(html, /\.right \{ right:30px; width:354px/);
assert.doesNotMatch(batch, /_Game Switchers/);
assert.match(batch, /start "Open Sturmovik Switcher" mshta\.exe/);
assert.doesNotMatch(batch, /start "Open Sturmovik Switcher" \/wait mshta\.exe/);
assert.match(html, /setTimeout\(cleanupGuiSource, 750\)/);

const switcherShortcut = utilityManifest.shortcuts.find(item => item.name === 'Open Sturmovik Switcher');
assert.ok(switcherShortcut);
assert.equal(switcherShortcut.target, 'Open_Sturmovik_Switcher.bat');
assert.equal(switcherShortcut.launchMode, 'hidden-batch-via-mshta');
assert.doesNotMatch(switcherShortcut.launcherArguments, /\s/);
let hiddenLaunch;
vm.runInNewContext(switcherShortcut.launcherArguments.slice('javascript:'.length), {
  ActiveXObject: function (name) {
    assert.equal(name, 'WScript.Shell');
    return { Run: (command, windowStyle, wait) => { hiddenLaunch = { command, windowStyle, wait }; } };
  },
  close: () => {}
}, { timeout: 1000 });
assert.deepEqual(hiddenLaunch, {
  command: 'cmd.exe /D /C ""Open_Sturmovik_Switcher.bat""',
  windowStyle: 0,
  wait: false
});

const iconLine = installer.split(/\r?\n/).find(line => line.includes('Name: "{userdesktop}\\Open Sturmovik Switcher"'));
assert.ok(iconLine);
const parameterMarker = 'Parameters: "';
let cursor = iconLine.indexOf(parameterMarker) + parameterMarker.length;
let installerArguments = '';
for (; cursor < iconLine.length; cursor++) {
  if (iconLine[cursor] !== '"') {
    installerArguments += iconLine[cursor];
  } else if (iconLine[cursor + 1] === '"') {
    installerArguments += '"';
    cursor++;
  } else {
    break;
  }
}
assert.equal(installerArguments, switcherShortcut.launcherArguments);
const scripts = [...html.matchAll(/<script\b[^>]*>([\s\S]*?)<\/script>/gi)];
assert.equal(scripts.length, 1);
const inputs = [...html.matchAll(/<input\b[^>]*>/gi)].map(([tag]) => ({
  name: /name="([^"]+)"/.exec(tag)?.[1],
  value: /value="([^"]+)"/.exec(tag)?.[1],
  checked: /checked=/.test(tag)
}));
const options = inputs.filter(input => input.name === 'hud').map(input => input.value);
assert.deepEqual(options, ['standard', 'immersion']);
const elements = {};
const context = vm.createContext({
  document: {
    getElementsByName: name => inputs.filter(input => input.name === name),
    getElementById: id => elements[id] ??= { style: {}, className: '', disabled: false }
  },
  setTimeout: fn => fn(),
  ActiveXObject: function () { throw new Error('ActiveX must never execute in this test'); }
});
vm.runInContext(scripts[0][1], context, { timeout: 1000 });
const select = (name, value) => {
  assert.ok(inputs.some(input => input.name === name && input.value === value));
  inputs.filter(input => input.name === name).forEach(input => input.checked = input.value === value);
};
let calls = 0;
context.fso = { FileExists: () => true };
context.bat = 'INERT-test-only.bat';
for (const [v, version] of ['408','409b','409m'].entries()) {
  for (const [m, mode] of ['original','standard','sixdof'].entries()) {
    select('version', version);
    select('mode', mode);
    const expected = 3 * v + m + 1;
    assert.equal(context.profileNumber(), expected);
    for (const hud of options) {
      select('hud', hud);
      context.runSwitch = (profile, actualHud) => {
        assert.equal(profile, expected);
        assert.equal(actualHud, mode === 'original' ? 'standard' : hud);
        calls++;
      };
      context.applyProfile();
    }
  }
}
assert.equal(calls, 18);
let stateText = '';
context.switchRoot = 'INERT';
context.fso = {
  BuildPath: (a, b) => `${a}/${b}`,
  FileExists: () => true,
  OpenTextFile: () => ({ ReadAll: () => stateText, Close: () => {} })
};
for (let profile = 1; profile <= 9; profile++) {
  for (const hud of options) {
    stateText = `profile=${profile}\r\nlabel=Profile ${profile}\r\nhud=${hud}\r\nmodhud=${hud}\r\n`;
    context.restoreState();
    context.updateSelection();
    assert.equal(context.profileNumber(), profile);
    assert.equal(context.selected('hud'), profile % 3 === 1 ? 'standard' : hud);
  }
}
const previous = context.profileNumber();
stateText = 'profile=99\r\nlabel=invalid';
context.restoreState();
assert.equal(context.profileNumber(), previous);
for (const version of ['408', '409b', '409m']) {
  select('version', version); select('mode', 'standard'); select('hud', 'immersion');
  context.updateSelection();
  assert.match(elements.summary.innerHTML, new RegExp(version === '408' ? '4\\.08m' : version.replace('.', '\\.')));
}
console.log('PASS: embedded IL-2-style GUI and selected Pacific Fighters Retail background found; 9 profile mappings and 18 profile/HUD dispatches.');
console.log('PASS: 18 saved-state restorations, stock-HUD guard, summaries and invalid-state guard.');
console.log('PASS: installed shortcut starts the single BAT through a hidden CMD; installer and utility manifest agree.');
console.log('Scope: selection logic only; no UI, game, capture or external process launched.');
