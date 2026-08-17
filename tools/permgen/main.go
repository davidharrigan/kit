// Command permgen turns a tool-agnostic permission YAML into the `permissions`
// block of a Claude Code settings.json.
//
// Usage:
//
//	permgen -config permissions.yaml -claude ../../dots/.claude/settings.json [-check]
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
	cfgPath := flag.String("config", "permissions.yaml", "path to the permission YAML source")
	claudePath := flag.String("claude", "", "settings.json to merge the permissions block into")
	check := flag.Bool("check", false, "do not write; exit non-zero if the file is out of date")
	flag.Parse()

	if *claudePath == "" {
		fatal("missing -claude <settings.json>")
	}

	cfg, err := loadConfig(*cfgPath)
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

func loadConfig(path string) (Config, error) {
	var cfg Config
	data, err := os.ReadFile(path)
	if err != nil {
		return cfg, err
	}
	err = yaml.Unmarshal(data, &cfg)
	return cfg, err
}

// renderClaude expands the neutral Config into the Claude permissions object.
func renderClaude(cfg Config) Perms {
	return Perms{
		Allow: dedup(renderSection(cfg.Allow)),
		Deny:  dedup(renderSection(cfg.Deny)),
		Ask:   dedup(renderSection(cfg.Ask)),
	}
}

// renderSection expands one section's bash/read/webfetch/raw lists into their
// wrapped Claude permission strings.
func renderSection(tm ToolMap) []string {
	out := expandBash(tm.Bash)
	out = append(out, wrapReadAll(tm.Read)...)
	out = append(out, wrapWebFetchAll(tm.WebFetch)...)
	out = append(out, tm.Raw...)
	return out
}

// expandBash wraps each bash value into its Claude permission string.
func expandBash(vals []string) []string {
	var out []string
	for _, v := range vals {
		v = strings.TrimSpace(v)
		if v == "" {
			continue
		}
		out = append(out, wrapBash(v))
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

func fatal(format string, args ...any) {
	fmt.Fprintf(os.Stderr, "permgen: "+format+"\n", args...)
	os.Exit(1)
}
