# LLM Council（Codex Skill 版）

这是一个**本地可用的 Codex CLI Skill**，把同一个问题并行交给多个模型（Claude、Codex、Gemini）：

1) **Stage 1**：并行收集观点  
2) **Stage 2**：交叉评审（peer review）  
3) **Stage 3**：由 **Claude Opus** 作为 Chairman 综合裁决并生成最终报告

最终报告会保存到当前项目的：`.council/final_report.md`。

本仓库已针对**超长输入（数千字）**做了处理：全链路通过“写入文件/走 stdin”传递 prompt，避免命令行参数过长导致报错。

---

## 依赖

必需（默认严格模式 require_all_members=1）：
- `claude`（Claude Code CLI）
- `codex`（Codex CLI）
- `gemini`（Google Gemini CLI）
- `jq`（用于部分 JSON/安全校验与脚本处理）

---

## 安装（到本机 `~/.codex`）

在本仓库根目录执行：

```bash
./scripts/install_codex_skill.sh
```

它会把以下内容安装到你的 Codex Home（默认 `~/.codex`）：
- skills：`council-orchestrator`、`council-chairman`
- prompts：`council`、`council-cleanup`、`council-help`、`council-status`、`council-config`、`council-verify-deps`
- helper：`~/.codex/bin/council`（可选，给终端用）

提示：安装后如未立刻生效，重启一次 Codex CLI。

---

## 使用（Codex 对话里）

推荐（问题可以直接跟在后面）：

```text
-/prompts:council 你的问题（可很长）
```

说明：Codex CLI 目前不会从 `~/.codex/prompts/` 动态注册新的 `/council` 这类 slash command；因此请使用 `-/prompts:...`（或 `/prompts:...`）形式调用。

如果你更想用 `/prompts:...`，注意它**只能接收 key=value** 形式：

```text
/prompts:council ARGUMENTS="你的问题"
```

清理本项目的临时工作目录：

```text
-/prompts:council-cleanup
```

查看帮助/状态：

```text
-/prompts:council-help
-/prompts:council-status
-/prompts:council-verify-deps
```

## 使用（终端里，可选）

安装脚本会放一个 helper 到 `~/.codex/bin/council`，你可以在任意项目目录运行：

```bash
~/.codex/bin/council "你的问题"
```

---

## 配置（`~/.council/config`）

配置文件是简单的 `key=value`，可用 `-/prompts:council-config` 管理：

```text
-/prompts:council-config
-/prompts:council-config set enabled_members claude,codex,gemini
-/prompts:council-config set min_quorum 3
-/prompts:council-config set require_all_members 1
-/prompts:council-config set timeout 600
-/prompts:council-config set max_prompt_length 200000
-/prompts:council-config reset
```

常用键：
- `enabled_members`：参与成员（默认 `claude,codex,gemini`）
- `min_quorum`：最小法定人数（默认 3）
- `require_all_members`：是否强制 3/3（默认 1；为 0 时允许缺席成员但会降级运行）
- `chairman_provider`：Stage 3 综合裁决使用哪个 CLI（`codex|claude|auto`，默认 `codex`）
- `timeout`：每个 CLI 调用超时（秒）
- `timeout_claude` / `timeout_codex` / `timeout_gemini`：分别为每个成员设置超时（秒）
- `chairman_timeout`：Stage 3（chairman）超时（秒）
- `max_prompt_length`：最大输入字符数（默认较大；超长问题可继续调高）

---

## 网络与代理（Proxy）

部分网络环境下直连 Google 端点会失败，导致 `gemini` 超时，从而在严格 `require_all_members=1` 时整个 Council 失败。

推荐两种做法（二选一）：

1) 通过环境变量指定代理（对所有调用有效）：

```bash
COUNCIL_PROXY_URL="http://127.0.0.1:7890" ~/.codex/bin/council "你的问题"
```

2) 在 `~/.council/config` 里写入代理（持久化）：

```text
proxy_url=http://127.0.0.1:7890
```

默认：若未配置任何代理且本机 `127.0.0.1:7890` 可连通，会自动使用它作为代理。

可选：启用扩展的自动探测本地代理端口（仅当未配置任何代理时生效）：

```bash
COUNCIL_AUTO_PROXY=1 ~/.codex/bin/council "你的问题"
```

---

## 沙箱兼容（Codex Tool Execution）

当 Council 由 Codex CLI 在受限环境中触发时，外部 CLI 可能无法写入真实的 `$HOME`。此时建议启用运行时 HOME 隔离：

```bash
COUNCIL_RUNTIME_HOME=1 ~/.codex/bin/council "你的问题"
```

`-/prompts:council` 已默认使用 `COUNCIL_RUNTIME_HOME=1`。

---

## 输出与产物

每次 `/council` 会重置并重建当前项目下的 `.council/`，典型文件：

- `query.txt`：原始问题
- `stage1_claude.txt` / `stage1_openai.txt` / `stage1_gemini.txt`：Stage 1 观点
- `stage2_review_*.txt`：Stage 2 交叉评审
- `final_report.md`：最终综合报告（最重要）

---

## 常见问题

### 1) Gemini 没有输出 / 缺席

默认严格模式会直接失败。先确保 `gemini` CLI 可用并已登录/配置好；或者显式关闭严格模式：

```text
-/prompts:council-config set require_all_members 0
```

### 2) 超长问题仍然被拒绝

把上限调大：

```text
-/prompts:council-config set max_prompt_length 300000
```

---

## 仓库访问（Read-Only）

为满足“必须能读仓库文件”的审查要求，本仓库的 council 运行方式会给各成员提供当前工作目录的只读访问能力：
- **Claude**：启用 `Read,Bash` 工具并 `--add-dir "$PWD"`，用于读取指定路径与检索定位行号（不会编辑文件）。
- **Gemini**：以 `--sandbox --include-directories "$PWD"` 运行，并开启 YOLO 自动批准（用于只读工具调用）。
- **Codex**：以 `exec -s read-only -C "$PWD" -a never` 运行（只读沙箱、非交互），并默认使用 `model_reasoning_effort="low"` 以降低长问题延迟。

## 目录结构

```text
.
├── codex/prompts/                # Prompt 模板（用 `-/prompts:...` 调用）
├── bin/                          # 可选：终端 helper（安装到 ~/.codex/bin）
├── skills/
│   ├── council-orchestrator/     # 编排脚本（Stage 1/2/3）
│   └── council-chairman/         # Chairman skill（主要给 Codex “理解用”）
└── scripts/
    └── install_codex_skill.sh    # 安装到 ~/.codex
```
