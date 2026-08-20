// Command permgen turns a tool-agnostic permission YAML into the `permissions`
// block of a Claude Code settings.json, adding the correct `rtk`-prefixed
// variants by asking `rtk hook check` how each command is actually rewritten.
//
// Usage:
//
//	permgen [-claude .claude/settings.json] [-config permissions.yaml] [-check] [-rtk rtk]
//
// By default the source is the merge of ~/.agents/permissions.yaml (global) and
// ./.agents/permissions.yaml (project); -config overrides with a single file.
// -claude defaults to ./.claude/settings.json (its directory must exist).
//
// The pipeline is: parse YAML -> neutral Config -> renderClaude. A future
// renderCodex would consume the same Config to emit Codex's config.toml; see
// README.md. rtk-prefixing is a Claude-render concern only (Codex has no such
// PreToolUse hook), so it lives here in renderClaude, not in the shared model.
package main

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"

	"gopkg.in/yaml.v3"
)

// sentinel is an unlikely trailing arg appended when probing rtk, so it sees a
// valid arg-bearing command (bare `git` is passthru, `git status ARG` rewrites).
const sentinel = "RTKSENTINEL9Z"

// ToolMap is the per-tool permission lists inside a section.
type ToolMap struct {
	Bash     []string `yaml:"bash"`
	Read     []string `yaml:"read"`
	WebFetch []string `yaml:"webfetch"`
	Raw      []string `yaml:"raw"`
}

// Config is the neutral, tool-agnostic permission model parsed from YAML.
type Config struct {
	Allow ToolMap `yaml:"allow"`
	Deny  ToolMap `yaml:"deny"`
	Ask   ToolMap `yaml:"ask"`
}

// Perms is the rendered Claude `permissions` object.
type Perms struct {
	Allow []string `json:"allow"`
	Deny  []string `json:"deny"`
	Ask   []string `json:"ask"`
}

func main() {
	cfgPath := flag.String("config", "", "single permission YAML source (overrides the default ~/.agents + ./.agents merge)")
	claudePath := flag.String("claude", filepath.Join(".claude", "settings.json"), "settings.json to merge the permissions block into")
	check := flag.Bool("check", false, "do not write; exit non-zero if the file is out of date")
	rtkBin := flag.String("rtk", "rtk", "rtk binary to probe for command rewrites")
	flag.Parse()

	if info, err := os.Stat(filepath.Dir(*claudePath)); err != nil || !info.IsDir() {
		fatal("%s does not exist", filepath.Dir(*claudePath))
	}

	cfg, err := loadSources(*cfgPath)
	if err != nil {
		fatal("load config: %v", err)
	}

	perms := renderClaude(cfg, *rtkBin)

	current, err := os.ReadFile(*claudePath)
	if err != nil {
		fatal("read %s: %v", *claudePath, err)
	}
	merged, err := mergePermissions(current, perms)
	if err != nil {
		fatal("merge: %v", err)
	}

	if *check {
		if !bytes.Equal(current, merged) {
			fmt.Fprintf(os.Stderr, "%s is out of date; run `make perms/generate`\n", *claudePath)
			os.Exit(1)
		}
		return
	}

	if bytes.Equal(current, merged) {
		fmt.Printf("%s already up to date\n", *claudePath)
		return
	}
	if err := os.WriteFile(*claudePath, merged, 0o644); err != nil {
		fatal("write %s: %v", *claudePath, err)
	}
	fmt.Printf("wrote permissions block to %s\n", *claudePath)
}

// loadSources returns the neutral Config for the run. If path is set, that
// single file is the source. Otherwise the default sources are merged in
// order: ~/.agents/permissions.yaml (global) then ./.agents/permissions.yaml
// (project). Missing default files are skipped silently.
func loadSources(path string) (Config, error) {
	if path != "" {
		return loadConfig(path)
	}

	var paths []string
	if home, err := os.UserHomeDir(); err == nil {
		paths = append(paths, filepath.Join(home, ".agents", "permissions.yaml"))
	}
	paths = append(paths, filepath.Join(".agents", "permissions.yaml"))

	var merged Config
	found := false
	for _, p := range paths {
		if _, err := os.Stat(p); err != nil {
			continue
		}
		cfg, err := loadConfig(p)
		if err != nil {
			return merged, fmt.Errorf("%s: %w", p, err)
		}
		mergeConfig(&merged, cfg)
		found = true
	}
	if !found {
		return merged, fmt.Errorf("no permissions.yaml found in %s", strings.Join(paths, " or "))
	}
	return merged, nil
}

func loadConfig(path string) (Config, error) {
	var cfg Config
	data, err := os.ReadFile(path)
	if err != nil {
		return cfg, err
	}
	err = yaml.Unmarshal(data, &cfg)
	return cfg, err
}

// mergeConfig appends src's lists onto dst, section by section and tool by
// tool. dedup in renderClaude collapses any overlap between sources.
func mergeConfig(dst *Config, src Config) {
	mergeToolMap(&dst.Allow, src.Allow)
	mergeToolMap(&dst.Deny, src.Deny)
	mergeToolMap(&dst.Ask, src.Ask)
}

func mergeToolMap(dst *ToolMap, src ToolMap) {
	dst.Bash = append(dst.Bash, src.Bash...)
	dst.Read = append(dst.Read, src.Read...)
	dst.WebFetch = append(dst.WebFetch, src.WebFetch...)
	dst.Raw = append(dst.Raw, src.Raw...)
}

// renderClaude expands the neutral Config into the Claude permissions object.
// Within each section the natural permissions come first, sorted
// alphabetically, followed by the auto-generated rtk-prefixed twins, also
// sorted alphabetically.
func renderClaude(cfg Config, rtkBin string) Perms {
	r := &rtkProbe{bin: rtkBin, cache: map[string]string{}}
	return Perms{
		Allow: renderSection(cfg.Allow, false, r),
		Deny:  renderSection(cfg.Deny, true, r),
		Ask:   renderSection(cfg.Ask, false, r),
	}
}

// renderSection expands one section's bash/read/webfetch/raw lists into their
// wrapped Claude permission strings: natural permissions (sorted) first, then
// the auto-generated rtk twins (sorted) at the bottom.
func renderSection(tm ToolMap, deny bool, r *rtkProbe) []string {
	natural, rtkTwins := expandBash(tm.Bash, deny, r)
	natural = append(natural, wrapReadAll(tm.Read)...)
	natural = append(natural, wrapWebFetchAll(tm.WebFetch)...)
	natural = append(natural, tm.Raw...)

	natural = dedup(natural)
	rtkTwins = dedup(rtkTwins)
	sort.Strings(natural)
	sort.Strings(rtkTwins)
	return append(natural, rtkTwins...)
}

// expandBash wraps each bash value and, separately, its auto-generated rtk
// variant. It returns the natural permissions and the rtk twins as two lists
// so the caller can place the twins at the bottom of the section.
//
// deny mode is broad and safety-first: every command-leading entry also gets a
// naive "rtk "-prefixed twin (no probe), so rtk-native invocations are blocked
// too. allow/ask mode is precise: it probes rtk for the real rewrite, which
// correctly maps cat/head/tail -> `rtk read` rather than `rtk cat`.
func expandBash(vals []string, deny bool, r *rtkProbe) (natural, rtkTwins []string) {
	for _, v := range vals {
		v = strings.TrimSpace(v)
		if v == "" {
			continue
		}
		natural = append(natural, wrapBash(v))
		if firstToken(v) == "rtk" {
			continue
		}
		if deny {
			if !strings.HasPrefix(v, "*") {
				rtkTwins = append(rtkTwins, wrapBash("rtk "+v))
			}
			continue
		}
		if strings.Contains(v, "*") {
			if r.covered(v) {
				rtkTwins = append(rtkTwins, wrapBash("rtk "+v))
			}
			continue
		}
		if rtkV, ok := r.rewrite(v); ok {
			rtkTwins = append(rtkTwins, wrapBash(rtkV))
		}
	}
	return natural, rtkTwins
}

func wrapReadAll(vals []string) []string {
	out := make([]string, 0, len(vals))
	for _, v := range vals {
		if v = strings.TrimSpace(v); v != "" {
			out = append(out, "Read("+v+")")
		}
	}
	return out
}

func wrapWebFetchAll(vals []string) []string {
	out := make([]string, 0, len(vals))
	for _, v := range vals {
		if v = strings.TrimSpace(v); v != "" {
			out = append(out, "WebFetch("+v+")")
		}
	}
	return out
}

// wrapBash applies the wrapping rule: a value with a "*" is a literal glob;
// otherwise ":*" is appended for prefix matching.
func wrapBash(v string) string {
	if strings.Contains(v, "*") {
		return "Bash(" + v + ")"
	}
	return "Bash(" + v + ":*)"
}

func firstToken(v string) string {
	f := strings.Fields(v)
	if len(f) == 0 {
		return ""
	}
	return f[0]
}

func dedup(in []string) []string {
	seen := map[string]bool{}
	out := in[:0]
	for _, v := range in {
		if !seen[v] {
			seen[v] = true
			out = append(out, v)
		}
	}
	return out
}

// rtkProbe queries `rtk hook check` and caches results.
type rtkProbe struct {
	bin   string
	cache map[string]string
}

func (r *rtkProbe) check(cmd string) string {
	if v, ok := r.cache[cmd]; ok {
		return v
	}
	out, err := exec.Command(r.bin, "hook", "check", cmd).Output()
	res := ""
	if err == nil {
		res = strings.TrimSpace(string(out))
	}
	r.cache[cmd] = res
	return res
}

// rewrite probes a star-free command and returns its exact rtk rewrite prefix
// (e.g. "cat" -> "rtk read", "git status" -> "rtk git status").
func (r *rtkProbe) rewrite(v string) (string, bool) {
	probe := v + " " + sentinel
	out := r.check(probe)
	if !strings.HasPrefix(out, "rtk ") {
		return "", false
	}
	return strings.TrimSuffix(out, " "+sentinel), true
}

// covered reports whether a glob command is rewritten by rtk (which, for the
// commands that reach this path, is always a pure "rtk " prefix).
func (r *rtkProbe) covered(v string) bool {
	probe := strings.ReplaceAll(v, "*", "x") + " " + sentinel
	return strings.HasPrefix(r.check(probe), "rtk ")
}

// mergePermissions replaces only the top-level "permissions" key in the
// settings JSON, preserving every other key and its order.
func mergePermissions(data []byte, perms Perms) ([]byte, error) {
	dec := json.NewDecoder(bytes.NewReader(data))
	tok, err := dec.Token()
	if err != nil {
		return nil, err
	}
	if d, ok := tok.(json.Delim); !ok || d != '{' {
		return nil, fmt.Errorf("settings.json is not a JSON object")
	}

	type kv struct {
		K string
		V json.RawMessage
	}
	var items []kv
	found := false
	permsRaw, err := marshalNoEscape(perms)
	if err != nil {
		return nil, err
	}
	for dec.More() {
		keyTok, err := dec.Token()
		if err != nil {
			return nil, err
		}
		key := keyTok.(string)
		var raw json.RawMessage
		if err := dec.Decode(&raw); err != nil {
			return nil, err
		}
		if key == "permissions" {
			raw = permsRaw
			found = true
		}
		items = append(items, kv{key, raw})
	}
	if !found {
		items = append(items, kv{"permissions", permsRaw})
	}

	var b bytes.Buffer
	b.WriteString("{\n")
	for i, it := range items {
		keyB, err := json.Marshal(it.K)
		if err != nil {
			return nil, err
		}
		var val bytes.Buffer
		if err := json.Indent(&val, it.V, "  ", "  "); err != nil {
			return nil, err
		}
		b.WriteString("  ")
		b.Write(keyB)
		b.WriteString(": ")
		b.Write(val.Bytes())
		if i < len(items)-1 {
			b.WriteByte(',')
		}
		b.WriteByte('\n')
	}
	b.WriteString("}\n")
	return b.Bytes(), nil
}

// marshalNoEscape marshals v to compact JSON without HTML-escaping <, >, & so
// shell redirection patterns stay readable in the settings file.
func marshalNoEscape(v any) ([]byte, error) {
	var buf bytes.Buffer
	enc := json.NewEncoder(&buf)
	enc.SetEscapeHTML(false)
	if err := enc.Encode(v); err != nil {
		return nil, err
	}
	return bytes.TrimRight(buf.Bytes(), "\n"), nil
}

func fatal(format string, args ...any) {
	fmt.Fprintf(os.Stderr, "permgen: "+format+"\n", args...)
	os.Exit(1)
}
