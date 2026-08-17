#!/usr/bin/env node
// cmdhook — a Bash PreToolUse policy hook that runs ALONGSIDE `rtk hook claude`
// as a second, parallel hook. It only ever emits `deny` or `ask` (never a
// rewrite / `updatedInput`), so it merges cleanly with rtk (most-restrictive
// wins) and can't collide with rtk's rewrites (cf. claude-code#15897).
//
// Policies:
//   - sed-coercion: `sed -i FILE` -> deny (use Edit); `sed` file-paging -> deny
//     (use Read). Piped/stream sed is left alone.
//   - gh-api gating: real `gh api` writes -> ask, unless the endpoint is
//     allow-listed for this repo (per-project .claude/cmdhook.toml). Reads and
//     allowed endpoints -> silent. Fail-closed (parse uncertainty -> ask).
//
// cd handling lives entirely in the static allow-list: with `cd` allowed, rtk
// already auto-allows `cd DIR && <allow-listed cmd>` compounds, so no rewrite
// is needed here.
//
// Fail-safe: any error / unknown shape -> emit nothing (defer). Never crashes.

import { execFileSync } from "node:child_process";
import { readFileSync } from "node:fs";
import { join } from "node:path";

function decision(kind, reason) {
  process.stdout.write(
    JSON.stringify({
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: kind,
        permissionDecisionReason: reason,
      },
    }) + "\n",
  );
  process.exit(0);
}
const deny = (r) => decision("deny", r);
const ask = (r) => decision("ask", r);
function defer() {
  process.exit(0); // no output -> other hooks + native engine decide
}

// ── project config (sectioned minimal TOML) ───────────────────────
function projectRoot(cwd) {
  try {
    return execFileSync("git", ["rev-parse", "--show-toplevel"], {
      cwd,
      encoding: "utf8",
      stdio: ["ignore", "pipe", "ignore"],
    }).trim();
  } catch {
    return null;
  }
}

function parseValue(v) {
  if (v === "true" || v === "false") return v === "true";
  if (v.startsWith("[")) return [...v.matchAll(/"([^"]*)"/g)].map((x) => x[1]);
  if (v.startsWith('"')) return v.slice(1, -1);
  return v;
}

function loadConfig(root) {
  const cfg = { sed_coercion: { enabled: true }, gh_api: { allow_endpoints: [] } };
  if (!root) return cfg;
  let text;
  try {
    text = readFileSync(join(root, ".claude", "cmdhook.toml"), "utf8");
  } catch {
    return cfg;
  }
  let section = null;
  for (const raw of text.split("\n")) {
    const line = raw.replace(/#.*$/, "").trim();
    if (!line) continue;
    const sec = line.match(/^\[([A-Za-z0-9_]+)\]$/);
    if (sec) {
      section = sec[1];
      continue;
    }
    const kv = line.match(/^([A-Za-z0-9_]+)\s*=\s*(.+)$/);
    if (!kv || !section) continue;
    (cfg[section] ??= {})[kv[1]] = parseValue(kv[2].trim());
  }
  return cfg;
}

// ── policies ──────────────────────────────────────────────────────
const SEP = /&&|\|\||[;&|]/;

// sed used as an editor/pager on a file -> deny, steer to Edit/Read.
function sedCoercion(command, cfg) {
  if (cfg.sed_coercion?.enabled === false) return;
  // In-place edit (before any pipe), regardless of quoting.
  if (/^[^|]*(^|[;&|]\s*)sed\b[^;&|]*\s-i\b/.test(command)) {
    deny("Use the Edit tool for in-place file edits instead of `sed -i`.");
  }
  // Paging/quiet read of a FILE as the first (non-piped) command:
  //   sed -n '1,50p' FILE | sed -n "1,50p" FILE | sed '50q' FILE
  const first = command.split(SEP)[0].trim();
  const paging =
    /^sed\s+(-n\s+)?(['"][^'"]*['"]|[0-9~$][^\s;|&]*)\s+\S/.test(first) &&
    /(p|q)\b|p['"]|q['"]/.test(first) &&
    !/\s-i\b/.test(first);
  if (paging) deny("Use the Read tool to read file ranges instead of `sed`.");
}

// gh api writes -> ask unless the endpoint is allow-listed for this repo.
function ghApiGate(command, cfg) {
  const m = command.match(/^\s*(?:rtk\s+)?gh\s+api\s+(.*)$/s);
  if (!m) return;
  let write = false;
  let endpoint = null;
  let tokens;
  try {
    tokens = m[1].match(/"[^"]*"|'[^']*'|\S+/g) || [];
  } catch {
    ask("Could not parse `gh api` arguments; prompting for safety.");
  }
  for (let i = 0; i < tokens.length; i++) {
    const t = tokens[i];
    if (t === "-X" || t === "--method") {
      const v = (tokens[i + 1] || "").toUpperCase();
      if (v && v !== "GET" && v !== "HEAD") write = true;
    } else if (/^--method=/.test(t)) {
      const v = t.split("=")[1].toUpperCase();
      if (v !== "GET" && v !== "HEAD") write = true;
    } else if (/^-X./.test(t)) {
      const v = t.slice(2).toUpperCase();
      if (v !== "GET" && v !== "HEAD") write = true;
    } else if (
      t === "-f" || t === "-F" || t === "--field" ||
      t === "--raw-field" || t === "--input" ||
      /^--field=|^--raw-field=|^--input=/.test(t)
    ) {
      write = true;
    } else if (!t.startsWith("-") && endpoint === null) {
      endpoint = t.replace(/^['"]|['"]$/g, "");
    }
  }
  if (!write) return; // read -> let the `gh api` allow rule auto-approve
  const allowed = (cfg.gh_api?.allow_endpoints || []).some(
    (suffix) => endpoint && endpoint.endsWith(suffix),
  );
  if (allowed) return; // per-repo permissive endpoint -> allow via base rule
  ask(`\`gh api\` write to ${endpoint || "an endpoint"} — approve this request?`);
}

// ── main ──────────────────────────────────────────────────────────
function main() {
  let payload;
  try {
    payload = JSON.parse(readFileSync(0, "utf8"));
  } catch {
    defer();
  }
  if (payload.tool_name && payload.tool_name !== "Bash") defer();
  const command = payload?.tool_input?.command;
  if (typeof command !== "string" || !command.trim()) defer();
  const cfg = loadConfig(projectRoot(payload.cwd || process.cwd()));

  ghApiGate(command, cfg); // fail-closed -> may ask; must run before defer
  sedCoercion(command, cfg);
  defer();
}

try {
  main();
} catch {
  defer(); // never crash-block a tool call
}
