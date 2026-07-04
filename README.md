# Paseo Docker Image

这个仓库用于构建自定义 Paseo 镜像，在官方镜像基础上安装 agent CLI。

基础镜像：

```dockerfile
FROM ghcr.io/getpaseo/paseo:latest
```

已安装 CLI：

- `@openai/codex`
- `@anthropic-ai/claude-code`
- `opencode-ai`

## 镜像

GitHub Actions 会把镜像发布到 GitHub Container Registry：

```text
ghcr.io/<owner>/<repo>:latest
```

镜像名会从 GitHub 仓库路径自动生成，并自动转成小写，避免 GHCR 镜像名大小写问题。

发布的 tag：

- 默认分支发布 `latest`
- 分支名 tag，例如 `master` 或 `main`
- 匹配 `v*.*.*` 的 git tag
- commit SHA tag，例如 `sha-<short-sha>`

## GitHub 设置

把这个仓库推送到 GitHub 后，`.github/workflows/docker-publish.yml` 会在 push、tag、pull request 或手动触发时构建镜像。pull request 只构建不推送，push/tag/manual 才会推送到 GHCR。

如果 GHCR 推送时报权限错误，检查：

- 仓库 `Settings -> Actions -> General -> Workflow permissions` 是否允许读写权限。
- 生成的 GHCR package 是否配置了正确访问权限。
- 如果 package 是 private，运行 Docker Compose 的机器需要先执行 `docker login ghcr.io`。

## Docker Compose

把官方镜像：

```yaml
image: ghcr.io/getpaseo/paseo:latest
```

替换成你的自定义镜像：

```yaml
image: ghcr.io/<owner>/<repo>:latest
```

其余 Compose 配置可以保持不变。

注意：仓库里的 Compose 不固定 `container_name`，避免和已有的 `paseo` 容器重名。如果你的服务器上还在运行旧官方容器，需要先停止/删除旧容器，或者给新编排配置不同的 `HTTP_PORT`，否则可能出现容器名或 `6767` 端口冲突。

## Agent CLI 自动升级

容器默认会在启动 Paseo 时检查 agent CLI 更新，默认间隔为 72 小时，也就是 3 天。

容器启动后还会运行一个后台检查任务，默认每小时检查一次。如果距离上次升级已经超过 72 小时，并且当前没有检测到 `codex`、`claude`、`opencode` 相关进程，才会执行升级。

可用环境变量：

- `AUTO_UPDATE_AGENT_CLIS`：是否启用自动升级，默认 `true`。
- `AUTO_UPDATE_AGENT_CLIS_BACKGROUND`：是否启用后台自动检查，默认 `true`。
- `AGENT_CLI_UPDATE_INTERVAL_HOURS`：升级检查间隔，默认 `72`。
- `AGENT_CLI_UPDATE_CHECK_INTERVAL_SECONDS`：后台检查频率，默认 `3600`。
- `AGENT_CLI_IDLE_PROCESS_NAMES`：判断空闲时检查的进程名，默认 `codex claude opencode`。
- `AGENT_CLI_CODEX_VERSION`：运行时安装的 Codex 版本，默认 `latest`。
- `AGENT_CLI_CLAUDE_CODE_VERSION`：运行时安装的 Claude Code 版本，默认 `latest`。
- `AGENT_CLI_OPENCODE_VERSION`：运行时安装的 OpenCode 版本，默认 `latest`。

升级失败不会阻止 Paseo 启动，容器会继续使用镜像内已经安装的版本。

如果需要把默认 `relay.paseo.sh` 换成自托管 relay，参考：

- [Paseo Relay 自部署说明](docs/paseo/relay-self-hosting.md)

## 本地构建测试

本地构建：

```powershell
docker build -t paseo-custom .
```

检查 CLI 是否安装成功：

```powershell
docker run --rm --entrypoint codex paseo-custom --version
docker run --rm --entrypoint claude paseo-custom --version
docker run --rm --entrypoint opencode paseo-custom --version
```
