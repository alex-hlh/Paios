#!/usr/bin/env node
// AIOS CLI entry point — cross-platform wrapper
// Delegates to aios.ps1 (Windows) or aios.sh (Unix)

const { spawn } = require('child_process');
const path = require('path');
const os = require('os');

const scriptsDir = path.join(__dirname, '..', 'scripts');
const args = process.argv.slice(2);

let child;

if (process.platform === 'win32') {
  child = spawn('powershell.exe', [
    '-NoProfile',
    '-ExecutionPolicy', 'Bypass',
    '-File', path.join(scriptsDir, 'aios.ps1'),
    ...args
  ], { stdio: 'inherit', shell: false });
} else {
  child = spawn('bash', [
    path.join(scriptsDir, 'aios.sh'),
    ...args
  ], { stdio: 'inherit', shell: false });
}

child.on('close', (code) => {
  process.exit(code);
});

child.on('error', (err) => {
  console.error('Failed to start AIOS CLI:', err.message);
  process.exit(1);
});
