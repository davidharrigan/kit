# Hermes Agent for the agent user. Imported by agent.nix; active when
# kit.agent.enable is set.
{ config, lib, pkgs, inputs, ... }:
let
  # Hermes Agent model routes. Codex slugs come from `hermes model` after the
  # Codex login.
  claudeProvider = "claude-subscription-directsdk-experimental";
  codexTop = "gpt-6.1-sol";
  codexSmall = "gpt-5.6-luna";
  opus = "claude-opus-5-5[1m]";
  sonnet = "claude-sonnet-5-5[1m]";

  # Claude subscription provider: drives agent's logged-in `claude` CLI
  # (/opt/homebrew/bin/claude, found without PATH changes).
  directsdk = pkgs.fetchFromGitHub {
    owner = "NousResearch";
    repo = "hermes-plugin-claude-subscription-directsdk";
    name = claudeProvider;
    rev = "4bc79c78031d1a042b5d8a7314ceea283db5c5e2"; # v0.3.3
    hash = "sha256-xrCfPlPKG5qYYFx7YMTo8Gp+bERcrSFvFZBUHgiM44M=";
  };

  # Hermes managed scope (/etc/hermes/config.yaml): pinned for every profile,
  # since profiles don't inherit ~/.hermes/config.yaml.
  hermesManaged = {
    auth.adopt_external_logins = false; # keep off agent's Claude Code / Codex logins
    terminal.backend = "local";
    approvals.timeout = 14400;
    # Side tasks (compression, memory review, titles, approvals...) default to
    # the main model; keep them off the Claude allowance.
    auxiliary = lib.genAttrs [
      "approval"
      "compression"
      "title_generation"
      "background_review"
      "curator"
      "goal_judge"
      "triage_specifier"
      "kanban_decomposer"
      "profile_describer"
    ] (_: {
      provider = "openai-codex";
      model = codexSmall;
    });
    checkpoints.enabled = true;
    lsp.trusted_workspaces = [ "/Users/agent/src" ];
    skills.disabled = [];
    # Hermes holds cron jobs through closed usage windows only for Codex.
    cron = {
      model = codexTop;
      model_provider = "openai-codex";
    };
    plugins.entries.${claudeProvider}.settings.claude_code_telemetry = false;
  };

  codexFallback = [
    {
      provider = "openai-codex";
      model = codexTop;
    }
  ];

  # Default profile: chat from Hermes Desktop. Also owns the kanban dispatcher.
  hermesSettings = {
    model = {
      provider = claudeProvider;
      default = opus;
    };
    fallback_providers = codexFallback;
    approvals.mode = "smart";
    memory.write_approval = true;
    kanban = {
      review_dispatch = true;
      auto_decompose = false;
      default_assignee = "coder";
      max_in_progress_per_profile = 3;
    };
  };

  # Default profile's .env. Routed profiles drop these vars, so only the default
  # profile's gh uses this login; the others keep agent's ~/.config/gh.
  hermesEnvironment.GH_CONFIG_DIR = "/Users/agent/.config/gh-david";

  # Kanban profiles, written to ~/.hermes/profiles/<name>/.
  hermesProfiles = {
    orchestrator = {
      config = {
        model = {
          provider = claudeProvider;
          default = opus;
        };
        fallback_providers = codexFallback;
        platform_toolsets.cli = [
          "kanban"
          "memory"
        ];
      };
      soul = ''
        You are the orchestrator. You turn GitHub issues and requests into
        kanban cards and watch the board. You never do repo work yourself.

        - Write each card as a self-contained brief: goal, context, constraints,
          acceptance criteria. Workers see only the card.
        - Assign cards to `coder` with workspace `worktree`,
          `--completion-contract OWNER/REPO` and a `--max-runtime`.
        - Pick the model per card: `sonnet` for routine, well-scoped work;
          `opus` for cross-cutting or design-heavy work, or a card that failed
          before.
        - Never assign cards to `default`.
      '';
    };
    coder = {
      config = {
        model = {
          provider = claudeProvider;
          default = sonnet;
        };
        fallback_providers = codexFallback;
        agent = {
          max_turns = 150;
          reasoning_overrides = {
            opus = "high";
            sonnet = "medium";
          };
        };
        approvals.single_query_mode = "approve";
        memory.memory_enabled = false;
        platform_toolsets.cli = [
          "file"
          "terminal"
          "web"
          "skills"
          "todo"
          "browser"
          "code_execution"
        ];
      };
      soul = ''
        You are the coder. You implement one kanban card and open a PR.

        - Work only in the card's workspace. If it has no `.git`, run
          `git worktree add` there first. Never edit the main checkout.
        - Make the smallest change that meets the card. No unrequested tests,
          features or abstractions. Match the patterns of the surrounding code.
        - Commit with conventional commit messages, push the branch and open a
          PR with `gh pr create`.
        - Hand off with `kanban_request_review(..., reviewer="reviewer")` and
          `metadata.published_pr` set. Never merge.
        - Call `kanban_heartbeat` at least hourly on long work.
      '';
    };
    reviewer = {
      config = {
        model = {
          provider = "openai-codex";
          default = codexTop;
        };
        fallback_providers = [
          {
            provider = claudeProvider;
            model = opus;
          }
        ];
        agent = {
          max_turns = 150;
          reasoning_effort = "high";
        };
        approvals.single_query_mode = "approve";
        memory.memory_enabled = false;
        platform_toolsets.cli = [
          "file"
          "terminal"
          "web"
          "skills"
        ];
      };
      soul = ''
        You are the reviewer. You review the PR on a kanban card.

        - Review for correctness first: bugs, broken behaviour, missed
          requirements from the card.
        - Report only substantive issues, each with its consequence and fix.
          Be concise.
        - Finish with `kanban_complete` when it is ready to merge, or
          `kanban_request_changes` with the issues.
      '';
    };
  };

  # Changes here need a gateway restart: kanban config is read at start.
  hermesConfigHash = builtins.hashString "sha256" (
    builtins.toJSON [
      hermesManaged
      hermesSettings
      hermesEnvironment
      hermesProfiles
    ]
  );
in
{
  config = lib.mkIf config.kit.agent.enable {
    environment.etc."hermes/config.yaml".text = builtins.toJSON hermesManaged;

    home-manager.users.agent = {
      imports = [
        inputs.hermes-agent.homeManagerModules.default
        (
          { lib, ... }:
          {
            # Hermes discovers plugins per profile home.
            home.file = lib.mapAttrs' (
              name: _:
              lib.nameValuePair ".hermes/profiles/${name}/plugins/${claudeProvider}" { source = directsdk; }
            ) hermesProfiles;

            # The backend's token for Hermes Desktop; generated once, kept out of the store.
            home.activation.hermesSessionToken =
              lib.hm.dag.entryBetween [ "setupLaunchAgents" ] [ "writeBoundary" ]
                ''
                  if [ ! -s "$HOME/.hermes/backend-session-token" ]; then
                    run mkdir -p "$HOME/.hermes"
                    run sh -c 'umask 077; ${pkgs.openssl}/bin/openssl rand -hex 32 > "$HOME/.hermes/backend-session-token"'
                  fi
                '';

            # Restart Hermes when its config changes; it reads kanban config only
            # at start. This interrupts any turn in flight.
            home.activation.hermesRestart =
              lib.hm.dag.entryAfter [ "hermesAgentSetup" "setupLaunchAgents" ]
                ''
                  if [ "$(cat "$HOME/.hermes/.kit-config-hash" 2>/dev/null)" != "${hermesConfigHash}" ]; then
                    for svc in hermes-agent hermes-backend; do
                      target="gui/$(id -u)/org.nix-community.home.$svc"
                      if /bin/launchctl print "$target" >/dev/null 2>&1; then
                        run /bin/launchctl kickstart -k "$target"
                      fi
                    done
                    run sh -c 'echo ${hermesConfigHash} > "$HOME/.hermes/.kit-config-hash"'
                  fi
                '';
          }
        )
      ];

      # Hermes Agent. Two launchd agents start at agent's GUI login and restart
      # if they exit: the gateway (cron, kanban dispatch for all profiles) and
      # the backend Hermes Desktop connects to, on 127.0.0.1:9119. Reach it from
      # a laptop with `ssh -N -L 9119:127.0.0.1:9119 agent@<host>` and the token
      # in ~/.hermes/backend-session-token. Logs: ~/Library/Logs/hermes-*.log.
      programs.hermes-agent.enable = true;
      services.hermes-agent = {
        enable = true;
        gateway.enable = true;
        backend = {
          mode = "serve";
          host = "127.0.0.1";
          port = 9119;
          sessionTokenFile = "/Users/agent/.hermes/backend-session-token";
        };
        # The launchd PATH holds only these, plus Hermes, bash, coreutils and git.
        extraPackages = with pkgs; [
          gh
          ripgrep
          jq
          go
          gopls
          cargo
          rustc
          rust-analyzer
          nodejs
        ];
        extraPlugins = [ directsdk ];
        settings = hermesSettings;
        environment = hermesEnvironment;
        hermesHomeFiles = lib.concatMapAttrs (name: p: {
          "profiles/${name}/config.yaml" = builtins.toJSON p.config;
          "profiles/${name}/SOUL.md" = p.soul;
        }) hermesProfiles;
      };
    };
  };
}
