// Tests for cmdhook.mjs — run with:  node --test dots/.claude/hooks/
//
// Integration style: spawn the real hook with a stdin payload and assert on its
// stdout JSON, exercising the actual PreToolUse contract (no internal mocking).

import { test } from "node:test";
import assert from "node:assert/strict";
import { execFileSync, execSync } from "node:child_process";
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const HOOK = join(dirname(fileURLToPath(import.meta.url)), "cmdhook.mjs");

// Run the hook with a raw stdin string; return parsed hookSpecificOutput or null.
function runRaw(input, cwd = process.cwd()) {
  const out = execFileSync("node", [HOOK], {
    input,
    encoding: "utf8",
    cwd,
  }).trim();
  return out ? JSON.parse(out).hookSpecificOutput : null;
}

// Run the hook with a Bash tool-use payload.
function run(command, cwd = process.cwd()) {
  return runRaw(JSON.stringify({ tool_name: "Bash", tool_input: { command }, cwd }), cwd);
}

const kind = (hso) => hso?.permissionDecision ?? null;

// ── sed-coercion ──────────────────────────────────────────────────
test("sed -i is denied and steers to Edit", () => {
  const hso = run("sed -i s/a/b/ foo.rs");
  assert.equal(kind(hso), "deny");
  assert.match(hso.permissionDecisionReason, /Edit tool/);
});

test("sed paging (single-quoted) is denied and steers to Read", () => {
  const hso = run("sed -n '1,50p' foo.rs");
  assert.equal(kind(hso), "deny");
  assert.match(hso.permissionDecisionReason, /Read tool/);
});

test("sed paging (double-quoted) is denied", () => {
  assert.equal(kind(run('sed -n "1,50p" foo.rs')), "deny");
});

test("sed paging (unquoted range) is denied", () => {
  assert.equal(kind(run("sed -n 1,50p foo.rs")), "deny");
});

test("sed quit form (Nq FILE) is denied", () => {
  assert.equal(kind(run("sed '50q' foo.rs")), "deny");
});

test("piped/stream sed is left alone (defer)", () => {
  assert.equal(run("cat foo | sed s/a/b/"), null);
});

test("sed can be disabled via project config", () => {
  const dir = mkRepo({ "[sed_coercion]": true, sed: "enabled = false" });
  try {
    assert.equal(run("sed -i s/a/b/ foo.rs", dir), null);
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

// ── gh-api gating ─────────────────────────────────────────────────
test("gh api write (-f) is asked", () => {
  const hso = run("gh api repos/o/r/issues/1/comments -f body=hi");
  assert.equal(kind(hso), "ask");
  assert.match(hso.permissionDecisionReason, /comments/);
});

test("gh api attached -XPOST is asked", () => {
  assert.equal(kind(run("gh api -XPOST repos/o/r/x")), "ask");
});

test("gh api --method=POST is asked", () => {
  assert.equal(kind(run("gh api --method=POST repos/o/r/x")), "ask");
});

test("gh api --input is asked", () => {
  assert.equal(kind(run("gh api repos/o/r/x --input body.json")), "ask");
});

test("gh api read defers", () => {
  assert.equal(run("gh api repos/o/r/issues"), null);
});

test("gh api explicit -X GET defers", () => {
  assert.equal(run("gh api -X GET repos/o/r/issues"), null);
});

test("gh api write to an allow-listed endpoint defers", () => {
  const dir = mkRepo({ gh: 'allow_endpoints = ["/comments"]' });
  try {
    assert.equal(run("gh api repos/o/r/issues/1/comments -f body=hi", dir), null);
    // a non-allow-listed write in the same repo still asks
    assert.equal(kind(run("gh api repos/o/r/labels -f name=bug", dir)), "ask");
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
});

// ── pass-through (cd handled by the allow-list, not here) ─────────
test("cd DIR && allow-listed cmd defers (rtk/allow-list handles it)", () => {
  assert.equal(run("cd /x && git status"), null);
});

test("a plain unrelated command defers", () => {
  assert.equal(run("git status"), null);
});

// ── fail-safe ─────────────────────────────────────────────────────
test("malformed JSON defers without crashing", () => {
  assert.equal(runRaw("not json"), null);
});

test("non-Bash tool defers", () => {
  assert.equal(runRaw(JSON.stringify({ tool_name: "Read", tool_input: {} })), null);
});

test("empty command defers", () => {
  assert.equal(run("   "), null);
});

// Build a throwaway git repo containing .claude/cmdhook.toml with the given
// section lines. `opts` maps a section marker to its body line(s).
function mkRepo(opts) {
  const dir = mkdtempSync(join(tmpdir(), "cmdhook-"));
  execSync("git init -q", { cwd: dir });
  mkdirSync(join(dir, ".claude"), { recursive: true });
  let toml = "";
  if (opts.sed) toml += `[sed_coercion]\n${opts.sed}\n`;
  if (opts.gh) toml += `[gh_api]\n${opts.gh}\n`;
  writeFileSync(join(dir, ".claude", "cmdhook.toml"), toml);
  return dir;
}
