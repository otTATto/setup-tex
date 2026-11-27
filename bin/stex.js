#!/usr/bin/env node
import { spawnSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { parseArgs } from 'node:util';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const windows = process.platform === 'win32';

const USAGE = `Usage: stex <command> [options]

Commands:
  setup [--texdir <dir>]                    Install a minimal TeX Live with the basic packages
  depends [<DEPENDS.txt>] [--texdir <dir>]  Install the packages on the hard lines of DEPENDS.txt
                                            (defaults to DEPENDS.txt in the current directory)
  check [--update]                          Compile the sample and compare it with the expected PDF

Options:
  -h, --help     Show this usage
  -v, --version  Show the version`;

// 各コマンドの CLI オプションと、それを sh / ps1 の引数に直す方法
const COMMANDS = {
  setup: {
    options: { texdir: { type: 'string' } },
    sh: ({ texdir }) => (texdir ? ['--texdir', resolve(texdir)] : []),
    ps1: ({ texdir }) => (texdir ? ['-TexDir', resolve(texdir)] : []),
  },
  depends: {
    options: { texdir: { type: 'string' } },
    positional: true,
    sh: ({ texdir }, path) => [
      ...(texdir ? ['--texdir', resolve(texdir)] : []),
      ...(path ? [resolve(path)] : []),
    ],
    ps1: ({ texdir }, path) => [
      ...(texdir ? ['-TexDir', resolve(texdir)] : []),
      ...(path ? ['-Path', resolve(path)] : []),
    ],
  },
  check: {
    options: { update: { type: 'boolean' } },
    sh: ({ update }) => (update ? ['--update'] : []),
    ps1: ({ update }) => (update ? ['-Update'] : []),
  },
};

/** @param {string} message */
const fail = (message) => {
  console.error(`❌ ${message}\n\n${USAGE}`);
  process.exit(2);
};

const [name, ...rest] = process.argv.slice(2);
if (name === undefined || name === '-h' || name === '--help') {
  console.log(USAGE);
  process.exit(name === undefined ? 2 : 0);
}
if (name === '-v' || name === '--version') {
  console.log(JSON.parse(readFileSync(join(root, 'package.json'), 'utf8')).version);
  process.exit(0);
}
const command = COMMANDS[name];
if (!command) fail(`unknown command: ${name}`);

let parsed;
try {
  parsed = parseArgs({
    args: rest,
    options: { ...command.options, help: { type: 'boolean', short: 'h' } },
    allowPositionals: true,
  });
} catch (err) {
  fail(err instanceof Error ? err.message : String(err));
}
const { values, positionals } = parsed;
if (values.help) {
  console.log(USAGE);
  process.exit(0);
}
if (positionals.length > (command.positional ? 1 : 0)) {
  fail(`too many arguments: ${positionals.join(' ')}`);
}

const [file, args] = windows
  ? [
      'powershell.exe',
      [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        join(root, 'scripts', `${name}.ps1`),
        ...command.ps1(values, positionals[0]),
      ],
    ]
  : ['sh', [join(root, 'scripts', `${name}.sh`), ...command.sh(values, positionals[0])]];

// pwsh (PowerShell 7) から起動すると、PSModulePath に PowerShell 7 のモジュールが入ったまま引き継がれ、
// Windows PowerShell 5.1 が Get-FileHash などを読み込めなくなるので、外して既定に戻させる
const env = windows
  ? Object.fromEntries(Object.entries(process.env).filter(([key]) => key.toLowerCase() !== 'psmodulepath'))
  : process.env;
const result = spawnSync(file, args, { stdio: 'inherit', env });
if (result.error) {
  console.error(`❌ failed to run ${file}: ${result.error.message}`);
  process.exit(1);
}
process.exit(result.status ?? 1);
