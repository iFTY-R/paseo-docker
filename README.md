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
