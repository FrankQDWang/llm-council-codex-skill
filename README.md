# LLM Council（Codex Skill 版）

这是一个**本地可用的 Codex CLI Skill**，提供 `/council "问题"` 触发命令，把同一个问题并行交给多个模型（Claude、Codex、可选 Gemini）：

1) **Stage 1**：并行收集观点  
2) **Stage 2**：交叉评审（peer review）  
3) **Stage 3**：由 **Claude Opus** 作为 Chairman 综合裁决并生成最终报告

最终报告会保存到当前项目的：`.council/final_report.md`。

本仓库已针对**超长输入（数千字）**做了处理：全链路通过“写入文件/走 stdin”传递 prompt，避免命令行参数过长导致报错。

---

## 依赖

必需：
- `codex`（Codex CLI）
- `claude`（Claude Code CLI，用于 Stage 1 的 Claude 成员 + Stage 3 的 Chairman）
- `jq`（用于部分 JSON/安全校验与脚本处理）

可选：
- `gemini`（Google Gemini CLI）

---

## 安装（到本机 `~/.codex`）

在本仓库根目录执行：

```bash
./scripts/install_codex_skill.sh
```

它会把以下内容安装到你的 Codex Home（默认 `~/.codex`）：
- skills：`council-orchestrator`、`council-chairman`
- prompts：`/council`、`/council-cleanup`、`/council-help`、`/council-status`、`/council-config`、`/council-verify-deps`

提示：安装后如未立刻生效，重启一次 Codex CLI。

---

## 使用

在任意项目目录打开 Codex CLI，然后直接运行：

```text
/council "你的问题（可很长，数千字也可以）"
```

清理本项目的临时工作目录：

```text
/council-cleanup
```

查看帮助/状态：

```text
/council-help
/council-status
/council-verify-deps
```

---

## 配置（`~/.council/config`）

配置文件是简单的 `key=value`，可用 `/council-config` 管理：

```text
/council-config
/council-config set enabled_members claude,codex
/council-config set min_quorum 2
/council-config set timeout 180
/council-config set max_prompt_length 200000
/council-config reset
```

常用键：
- `enabled_members`：参与成员（默认 `claude,codex,gemini`）
- `min_quorum`：最小法定人数（peer review 至少需要 2；如只想单模型跑通可设为 1）
- `timeout`：每个 CLI 调用超时（秒）
- `max_prompt_length`：最大输入字符数（默认较大；超长问题可继续调高）

---

## 输出与产物

每次 `/council` 会重置并重建当前项目下的 `.council/`，典型文件：

- `query.txt`：原始问题
- `stage1_claude.txt` / `stage1_openai.txt` / `stage1_gemini.txt`：Stage 1 观点
- `stage2_review_*.txt`：Stage 2 交叉评审
- `final_report.md`：最终综合报告（最重要）

---

## 常见问题

### 1) Gemini 已安装但经常卡住/没配置好

直接禁用 Gemini：

```text
/council-config set enabled_members claude,codex
```

### 2) 超长问题仍然被拒绝

把上限调大：

```text
/council-config set max_prompt_length 300000
```

### 3) 只想快速跑通（只用 Claude）

```text
/council-config set enabled_members claude
/council-config set min_quorum 1
```

---

## 目录结构

```text
.
├── codex/prompts/                # Codex CLI 的 /xxx 触发命令
├── skills/
│   ├── council-orchestrator/     # 编排脚本（Stage 1/2/3）
│   └── council-chairman/         # Chairman skill（主要给 Codex “理解用”）
└── scripts/
    └── install_codex_skill.sh    # 安装到 ~/.codex
```

