/**
 * A Claude Code `SessionStart` hook for Rex terminals, from Tower's rex connector. Run it with bun.
 *
 * It reports the Claude session a Rex terminal now runs by writing `~/.config/tower/rex/sessions/<block id>`, which
 * the connector reads to give the terminal's agent session that id. Claude Code runs the hook as its own child, with
 * the hook's input as JSON on stdin. Outside a Rex terminal, and for a subagent's session, it writes nothing.
 *
 * The script imports nothing from the repo, so it runs from `~/.claude/hooks`.
 */
import { mkdir, rename } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";

const input = (await Bun.stdin.json()) as {
  hook_event_name?: string;
  session_id?: string;
  /** Set when the session that starts is a subagent's. */
  agent_id?: string;
};
const block = process.env.REX_BLOCK;

if (block && input.hook_event_name === "SessionStart" && !input.agent_id && input.session_id) {
  const dir = join(homedir(), ".config", "tower", "rex", "sessions");
  await mkdir(dir, { recursive: true });
  // Written beside the report and renamed over it, so the connector never reads half a report.
  const draft = join(dir, `.${block}.${process.pid}`);
  // `pid` is the Claude Code process, which is this hook's parent.
  await Bun.write(draft, JSON.stringify({ session: input.session_id, pid: process.ppid }));
  await rename(draft, join(dir, block));
}
