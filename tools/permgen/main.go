// Command permgen turns a tool-agnostic permission YAML into the `permissions`
// block of a Claude Code settings.json.
//
// Usage:
//
//	permgen [-claude .claude/settings.json] [-config permissions.yaml] [-check]
//
// By default the source is the merge of ~/.agents/permissions.yaml (global) and
// ./.agents/permissions.yaml (project); -config overrides with a single file.
// -claude defaults to ./.claude/settings.json (its directory must exist).
//
// The pipeline is: parse YAML -> neutral Config -> renderClaude. A future
// renderCodex would consume the same Config to emit Codex's config.toml; see
// README.md.
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
	flag.Parse()

	if info, err := os.Stat(filepath.Dir(*claudePath)); err != nil || !info.IsDir() {
		fatal("%s does not exist", filepath.Dir(*claudePath))
	}

	cfg, err := loadSources(*cfgPath)
	if err != nil {
		fatal("load config: %v", err)
	}

	perms := renderClaude(cfg)

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
			fmt.Fprintf(os.Stderr, "%s is out of date; run `make perms/generate`\n\n", *claudePath)
			os.Stderr.Write(diffUnified(*claudePath, merged))
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
// Within each section the permissions are sorted alphabetically.
func renderClaude(cfg Config) Perms {
	return Perms{
		Allow: renderSection(cfg.Allow),
		Deny:  renderSection(cfg.Deny),
		Ask:   renderSection(cfg.Ask),
	}
}

// renderSection expands one section's bash/read/webfetch/raw lists into their
// wrapped Claude permission strings, deduplicated and sorted.
func renderSection(tm ToolMap) []string {
	out := wrapBashAll(tm.Bash)
	out = append(out, wrapReadAll(tm.Read)...)
	out = append(out, wrapWebFetchAll(tm.WebFetch)...)
	out = append(out, tm.Raw...)

	out = dedup(out)
	sort.Strings(out)
	return out
}

func wrapBashAll(vals []string) []string {
	out := make([]string, 0, len(vals))
	for _, v := range vals {
		if v = strings.TrimSpace(v); v != "" {
			out = append(out, wrapBash(v))
		}
	}
	return out
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

// diffUnified returns a unified diff of the on-disk file against the freshly
// generated bytes, using the system `diff`. The current file is read from path;
// merged is fed on stdin. diff exits 1 when the inputs differ, which is expected
// here, so only a failure to run at all falls back to a plain notice.
func diffUnified(path string, merged []byte) []byte {
	cmd := exec.Command("diff", "-u", "-L", path+" (current)", "-L", path+" (generated)", path, "-")
	cmd.Stdin = bytes.NewReader(merged)
	out, err := cmd.Output()
	if err != nil {
		if _, ok := err.(*exec.ExitError); !ok {
			return []byte("(could not run `diff` to show changes)\n")
		}
	}
	return out
}

func fatal(format string, args ...any) {
	fmt.Fprintf(os.Stderr, "permgen: "+format+"\n", args...)
	os.Exit(1)
}
