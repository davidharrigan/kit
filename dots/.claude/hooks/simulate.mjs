#!/usr/bin/env node
// simulate.mjs — dry-run predictor for how Claude Code's PreToolUse pipeline
// resolves a Bash command. It runs the REAL hooks (rtk hook claude + cmdhook)
// on a synthetic tool-use payload, merges their outputs the way CC documents,
// and — for the no-hook-decision case — predicts the outcome from the static
// allow/deny/ask lists in settings.json (compound-aware, like CC).
//
// It does NOT invoke the model and does NOT execute the command. This is a
// model of CC's DOCUMENTED behavior, not CC itself; use `claude -p
// --output-format stream-json --include-hook-events` for ground truth.
//
// Usage:
//   node simulate.mjs "cd /x && just test"          # one command
//   node simulate.mjs --cases simulate.cases.json   # batch / assertion mode
//   node simulate.mjs --cases … --cwd /some/repo    # resolve project config there
//
// Decision precedence (most restrictive wins), per CC docs:
//   deny (hook or static)  >  ask (hook or static; a static `ask` also overrides
//   a hook `allow`)  >  allow (hook or static)  >  prompt (unlisted default).

import { execFileSync } from "node:child_process";
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const HERE = dirname(fileURLToPath(import.meta.url));
const CMDHOOK = join(HERE, "cmdhook.mjs");
const SETTINGS = join(HERE, "..", "settings.json"); // dots/.claude/settings.json

const SEP = /&&|\|\||[;&|]/;

// ── run one hook (subprocess) and return its hookSpecificOutput ────
function runHook(cmd, args, payload) {
  try {
    const out = execFileSync(cmd, args, {
      input: JSON.stringify(payload),
      encoding: "utf8",
      stdio: ["pipe", "pipe", "ignore"],
    }).trim();
    return out ? JSON.parse(out).hookSpecificOutput ?? null : null;
  } catch {
    return null;
  }
}

// ── static allow/deny/ask matching (compound-aware) ───────────────
function loadRules() {
  const perms = JSON.parse(readFileSync(SETTINGS, "utf8")).permissions ?? {};
  const bash = (arr) =>
    (arr ?? [])
      .filter((s) => s.startsWith("Bash("))
      .map((s) => s.slice(5, -1)); // strip Bash( … )
  return { deny: bash(perms.deny), ask: bash(perms.ask), allow: bash(perms.allow) };
}

function patternToRegex(pat) {
  // "git status:*" -> prefix match; "rm -rf /*" -> glob; else exact.
  let body = pat;
  let anchorEnd = "$";
  if (body.endsWith(":*")) {
    body = body.slice(0, -2);
    anchorEnd = "(\\s|$)"; // prefix: next is whitespace or end
  }
  const rx = body
    .replace(/[.+?^${}()|[\]\\]/g, "\\$&") // escape regex metachars
    .replace(/\*/g, ".*"); // glob star
  return new RegExp("^" + rx + anchorEnd);
}

function segMatches(seg, patterns) {
  return patterns.some((p) => patternToRegex(p).test(seg));
}

// Verdict for a whole (possibly compound) command against the static lists.
function staticVerdict(command, rules) {
  const segs = command.split(SEP).map((s) => s.trim()).filter(Boolean);
  if (segs.length === 0) return "default";
  if (segs.some((s) => segMatches(s, rules.deny))) return "deny";
  if (segs.some((s) => segMatches(s, rules.ask))) return "ask";
  if (segs.every((s) => segMatches(s, rules.allow))) return "allow";
  return "default"; // unlisted -> CC prompts
}

// ── full pipeline for one command ─────────────────────────────────
function simulate(command, cwd, rules) {
  const payload = { tool_name: "Bash", tool_input: { command }, cwd };
  const rtk = runHook("rtk", ["hook", "claude"], payload);
  const cmd = runHook("node", [CMDHOOK], payload);

  const rewritten = rtk?.updatedInput?.command ?? command;
  const hookDecs = [rtk?.permissionDecision, cmd?.permissionDecision].filter(Boolean);
  const stat = staticVerdict(rewritten, rules);

  let final;
  if (hookDecs.includes("deny") || stat === "deny") final = "deny";
  else if (hookDecs.includes("ask") || stat === "ask") final = "prompt";
  else if (hookDecs.includes("allow") || stat === "allow") final = "allow";
  else final = "prompt"; // unlisted default

  const reason =
    cmd?.permissionDecisionReason ??
    rtk?.permissionDecisionReason ??
    (final === "allow" && stat === "allow" ? "static allow-list" : "");
  return { command, rewritten, final, reason };
}

// ── CLI ───────────────────────────────────────────────────────────
function parseArgs(argv) {
  const a = { cwd: process.cwd(), cases: null, command: null };
  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === "--cwd") a.cwd = argv[++i];
    else if (argv[i] === "--cases") a.cases = argv[++i];
    else a.command = argv[i];
  }
  return a;
}

function main() {
  const args = parseArgs(process.argv.slice(2));
  const rules = loadRules();

  if (args.cases) {
    const cases = JSON.parse(readFileSync(args.cases, "utf8"));
    let failed = 0;
    for (const c of cases) {
      const r = simulate(c.command, c.cwd ?? args.cwd, rules);
      const ok = !c.expect || c.expect === r.final;
      if (!ok) failed++;
      const mark = c.expect ? (ok ? "✔" : "✘") : "•";
      const exp = c.expect && !ok ? `  (expected ${c.expect})` : "";
      const rw = r.rewritten !== r.command ? `  →  ${r.rewritten}` : "";
      console.log(`${mark} ${r.final.padEnd(6)} ${c.command}${rw}${exp}`);
    }
    console.log(`\n${cases.length} cases, ${failed} failed`);
    process.exit(failed ? 1 : 0);
  }

  if (!args.command) {
    console.error('usage: simulate.mjs "<command>"  |  --cases <file.json> [--cwd DIR]');
    process.exit(2);
  }
  const r = simulate(args.command, args.cwd, rules);
  console.log(`command:   ${r.command}`);
  if (r.rewritten !== r.command) console.log(`rewritten: ${r.rewritten}`);
  console.log(`decision:  ${r.final}${r.reason ? `  (${r.reason})` : ""}`);
}

main();
