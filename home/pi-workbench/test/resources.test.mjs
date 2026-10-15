import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { DefaultResourceLoader, SettingsManager } from '@earendil-works/pi-coding-agent';

test('native Pi discovers the local manifest, extension and skill without provider calls', async t => {
  const cwd = fs.mkdtempSync(path.join(os.tmpdir(), 'workbench-resources-'));
  t.after(() => fs.rmSync(cwd, { recursive: true, force: true }));
  const packagePath = fileURLToPath(new URL('..', import.meta.url));
  const settingsManager = SettingsManager.inMemory({ packages: [packagePath] });
  const loader = new DefaultResourceLoader({ cwd, agentDir: path.join(cwd, 'agent'),
    settingsManager, noContextFiles: true, noPromptTemplates: true, noThemes: true });
  await loader.reload();
  const extensions = loader.getExtensions();
  assert.deepEqual(extensions.errors, []);
  assert.equal(extensions.extensions.length, 1);
  const loaded = extensions.extensions[0];
  assert(loaded.tools.has('workbench'));
  assert(loaded.commands.has('workbench'));
  assert.equal(loader.getSkills().skills.find(s => s.name === 'workbench')?.name, 'workbench');
  assert.deepEqual(loader.getSkills().diagnostics, []);
  assert.equal(loader.getSystemPrompt(), undefined);
});
