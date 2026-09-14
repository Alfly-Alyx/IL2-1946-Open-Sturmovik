// Tests the JavaScript in the dedicated HTA with an inert DOM. No Windows UI,
// ActiveX, game or capture process can be started by this test.
'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const root = path.resolve(__dirname, '..', '..', '..');
const batch = fs.readFileSync(path.join(root, 'Open_Sturmovik_Switcher.bat'), 'utf8');
const utilityManifest = JSON.parse(fs.readFileSync(path.join(root, 'WIP', 'development', 'manifests', 'utilities-v1.15.json'), 'utf8'));
const launcherVbs = fs.readFileSync(path.join(root, '_Game Switcher', 'Open_Sturmovik_Switcher.vbs'), 'utf8');
const installerPath = path.join(root, 'WIP', 'development', 'installer', 'Open_Sturmovik_1.15.iss');
const htmlPath = path.join(root, '_Game Switcher', 'Open_Sturmovik_Switcher.hta');
const html = fs.readFileSync(htmlPath, 'utf8');
assert.match(html, /^<!doctype html>/i);
assert.match(html, /content="IE=edge"/);
assert.doesNotMatch(html.slice(0, 512), /%~f0|SWITCHER_GUI_LINE|SWITCHER_GUI_TEMP/);
assert.doesNotMatch(batch, /### OPEN_STURMOVIK_GUI ###/);
assert.match(batch, /SWITCHER_GUI_FILE=%SWITCH_ROOT%\\Open_Sturmovik_Switcher\.hta/);
assert.match(html, /Open_Sturmovik_Switcher_Background__Pacific_Fighters_Retail\.jpg/);
assert.match(html, /function fileUrl\(path\)/);
assert.doesNotMatch(batch, /SWITCHER_GUI_BACKGROUND_TEMP|SWITCHER_GUI_TEMP|more \+%SWITCHER_GUI_LINE%/);
assert.match(html, /font-family:"Trebuchet MS",Tahoma,Arial,sans-serif/);
assert.match(html, /border:4px ridge #89938e/);
assert.match(html, /icon="Resources\\Icons\\Open_Sturmovik_Switcher\.ico"/);
assert.match(html, /width:820px; height:598px/);
assert.match(html, /\.left \{ left:30px; width:380px/);
assert.match(html, /\.right \{ right:30px; width:354px/);
assert.doesNotMatch(batch, /_Game Switchers/);
assert.match(batch, /start "" \/NORMAL "%SystemRoot%\\System32\\mshta\.exe"/);
assert.doesNotMatch(batch, /start "" \/wait/i);
assert.match(html, /setTimeout\(cleanupGuiSource, 750\)/);
assert.match(html, /padding:4px 0 4px 12px;/);

const switcherShortcut = utilityManifest.shortcuts.find(item => item.name === 'Open Sturmovik Switcher');
assert.ok(switcherShortcut);
assert.equal(switcherShortcut.target, 'Open_Sturmovik_Switcher.bat');
assert.equal(switcherShortcut.launchMode, 'hidden-batch-via-vbs');
assert.equal(switcherShortcut.launcher, '_Game Switcher\\Open_Sturmovik_Switcher.vbs');
assert.match(launcherVbs, /Open_Sturmovik_Switcher\.hta/);
assert.match(launcherVbs, /shell\.Run Quote\(mshta\)[\s\S]*, 1, False/);
assert.doesNotMatch(launcherVbs, /%ComSpec%|cmd\.exe/i);
assert.doesNotMatch(launcherVbs, /[A-Za-z]:\\/);
assert.doesNotMatch(launcherVbs, /Set-OpenSturmovikNativeResolution|powershell/i);

if (fs.existsSync(installerPath)) {
  const installer = fs.readFileSync(installerPath, 'utf8');
  const iconLine = installer.split(/\r?\n/).find(line => line.includes('Name: "{userdesktop}\\Open Sturmovik Switcher"'));
  assert.ok(iconLine);
  assert.match(iconLine, /Filename: "{sys}\\wscript\.exe"/);
  assert.match(iconLine, /Parameters: """{app}\\_Game Switcher\\Open_Sturmovik_Switcher\.vbs"""/);
} else {
  console.log('SKIP: final installer source is absent; installer shortcut consistency is not validated.');
}
const scripts = [...html.matchAll(/<script\b[^>]*>([\s\S]*?)<\/script>/gi)];
assert.equal(scripts.length, 1);
const inputs = [...html.matchAll(/<input\b[^>]*>/gi)].map(([tag]) => ({
  name: /name="([^"]+)"/.exec(tag)?.[1],
  value: /value="([^"]+)"/.exec(tag)?.[1],
  checked: /checked=/.test(tag)
}));
const options = inputs.filter(input => input.name === 'hud').map(input => input.value);
assert.deepEqual(options, ['standard', 'immersion']);
const languageMarkup = /<select[^>]*id="language"[^>]*>([\s\S]*?)<\/select>/i.exec(html)?.[1] || '';
const languages = [...languageMarkup.matchAll(/<option value="(fr|us|ru|de|cs|hu|pl)"/g)].map(match => match[1]);
assert.deepEqual(languages, ['fr', 'us', 'de', 'ru', 'cs', 'hu', 'pl']);
assert.match(html, /\.languageSelect \{[^\r\n]*padding:4px 0 4px 12px;/);
assert.match(html, /\.languageSelect::\-ms\-expand \{[^\r\n]*width:31px;[^\r\n]*border-left:2px ridge #c0c8bf;[^\r\n]*color:#f3f4ee;[^\r\n]*background-image:linear-gradient[^\r\n]*box-shadow:/);
assert.match(html, /\.languageSelect:hover::\-ms\-expand, \.languageSelect:focus::\-ms\-expand \{[^\r\n]*color:#ffffff;[^\r\n]*background-image:linear-gradient/);
assert.match(html, /\.button \{[^\r\n]*text-align:center;/);
assert.match(html, /\.button\.credits \{ position:absolute; left:50%; bottom:-8px;/);
assert.match(html, /\.button\.back \{[^\r\n]*background:#315f79;[^\r\n]*box-shadow:/);
assert.match(html, /\.button\.back:hover, \.button\.back:focus \{[^\r\n]*background:#3d7695;/);
assert.match(html, /class="button back" id="creditsBack"[^>]*onclick="closeCredits\(\)"/);
assert.match(html, /class="button back"[^>]*onclick="backToForm\(\)"/);
assert.match(html, /id="progressBar"/);
assert.match(html, /shell\.Run\('cmd\.exe[\s\S]*, 0, false\)/);
assert.doesNotMatch(html, /shell\.Run\([^\r\n]*, 0, true\)/);
const elements = { language: { style: {}, className: '', disabled: false, value: 'fr', focus: function () {} } };
const context = vm.createContext({
  document: {
    getElementsByName: name => inputs.filter(input => input.name === name),
    getElementById: id => elements[id] ??= { style: {}, className: '', disabled: false, focus: function () {} }
  },
  setTimeout: fn => fn(),
  ActiveXObject: function () { throw new Error('ActiveX must never execute in this test'); }
});
vm.runInContext(scripts[0][1], context, { timeout: 1000 });
const select = (name, value) => {
  if (name === 'language') {
    assert.ok(languages.includes(value)); elements.language.value = value; return;
  }
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
      for (const language of languages) {
        select('hud', hud); select('language', language);
        context.runSwitch = (profile, actualHud, actualLanguage) => {
          assert.equal(profile, expected);
          assert.equal(actualHud, mode === 'original' ? 'standard' : hud);
          assert.equal(actualLanguage, language); calls++;
        };
        context.applyProfile();
      }
    }
  }
}
assert.equal(calls, 126);
let stateText = '';
context.switchRoot = 'INERT';
context.fso = {
  BuildPath: (a, b) => `${a}/${b}`,
  FileExists: () => true,
  OpenTextFile: () => ({ ReadAll: () => stateText, Close: () => {} })
};
for (let profile = 1; profile <= 9; profile++) {
  for (const hud of options) {
    for (const language of languages) {
      stateText = `profile=${profile}\r\nlabel=Profile ${profile}\r\nhud=${hud}\r\nmodhud=${hud}\r\nlanguage=${language}\r\n`;
      context.restoreState(); context.updateSelection();
      assert.equal(context.profileNumber(), profile);
      assert.equal(context.selected('hud'), profile % 3 === 1 ? 'standard' : hud);
      assert.equal(context.selectedLanguage(), language);
    }
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
console.log('PASS: dedicated IL-2-style HTA and direct Pacific Fighters Retail background found; 9 profile mappings and 126 profile/HUD/language dispatches.');
console.log('PASS: 126 saved-state restorations, seven-language dropdown, stock-HUD guard, summaries and invalid-state guard.');
console.log('PASS: utility manifest shortcut uses the relative VBS launcher; BAT forces the HTA window to normal visibility.');
console.log('Scope: selection logic only; no UI, game, capture or external process launched.');

// Credits are a self-contained page. Opening and closing them must never
// apply a profile, read a saved profile or discard unsaved radio choices.
assert.match(html, /id="creditsButton"[^>]*onclick="showCredits\(\)"/);
assert.match(html, /id="creditsPage"/);
assert.match(html, /id="creditsScroll"/);
assert.match(html, /id="creditsBack"[^>]*onclick="closeCredits\(\)"/);
elements.apply.disabled = false;
const savedRestorer = context.restoreState;
const savedUpdater = context.updateSelection;
const savedFso = context.fso;
context.restoreState = () => { throw new Error('Credits must preserve pending choices'); };
context.updateSelection = () => { throw new Error('Credits must not alter pending choices'); };
context.fso = new Proxy({}, { get: () => { throw new Error('Credits must not need filesystem access'); } });
context.shell = { Run: () => { throw new Error('Credits navigation must not start a process'); } };
for (const version of ['408', '409b', '409m']) {
  select('version', version); select('mode', 'sixdof'); select('hud', 'immersion'); select('language', 'us');
  const pending = inputs.map(input => input.checked);
  const pendingLanguage = elements.language.value;
  context.showCredits();
  assert.equal(elements.form.style.display, 'none');
  assert.equal(elements.creditsPage.style.display, 'block');
  context.closeCredits();
  assert.equal(elements.form.style.display, 'block');
  assert.equal(elements.creditsPage.style.display, 'none');
  assert.deepEqual(inputs.map(input => input.checked), pending);
  assert.equal(elements.language.value, pendingLanguage);
}
context.restoreState = savedRestorer;
context.updateSelection = savedUpdater;
context.fso = savedFso;
assert.match(html, /forum All Aircraft Arcade \(AAA\)/);
assert.doesNotMatch(html, /AAA Community Installer|Socle historique du pack|modules AAA/);
assert.doesNotMatch(html, /Zuti Moving Dogfight Server|\|ZUTI\||Certificates AI mod|Fireballs Carrier Takeoff/);
assert.match(html, /PlusWave Expansions/);
assert.match(html, /WindConfig v3/);
const byteData = fs.readFileSync(path.join(root, 'Open_Sturmovik_Switcher.bat'));
assert.notEqual(byteData.subarray(0, 3).toString('hex'), 'efbbbf', 'BAT must not have a BOM');
assert.doesNotMatch(batch, /(?<!\r)\n/, 'BAT must use CRLF throughout');
console.log('PASS: self-contained Credits page, pending choices preserved across 3 versions, no filesystem or process access during navigation; CRLF and encoding.');
