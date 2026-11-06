# typescript-lsp

TypeScript/JavaScript code intelligence for Claude Code, using the language
server built into the native TypeScript compiler.

## Requirements

`tsc` on `PATH` at **TypeScript 7.0 or newer**. `--lsp` exists only in the
native compiler; a 5.x `tsc` has no such flag and the server will not start.

## Why not typescript-language-server

Anthropic's `typescript-lsp` plugin runs `typescript-language-server`, which
loads `tsserver.js` out of the *workspace's* `node_modules/typescript` — it
never consults `PATH`. It therefore fails outright in any repository without a
local TypeScript 5.x dependency, and in any repository that has moved to
TypeScript 7, which ships no `tsserver.js` at all.

Disable `typescript-lsp@claude-plugins-official` when enabling this one, so a
single server handles these extensions.
