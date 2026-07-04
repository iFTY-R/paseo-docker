# Paseo Relay 自部署说明

本文整理当前仓库使用自定义 Paseo Docker 镜像时，如何把默认 `relay.paseo.sh` 替换成自己的 relay 服务。

> 核心结论：Paseo 官方有 relay 相关说明和官方 relay 实现，但目前官方资料是分散在 README、安全文档和 `packages/relay` 源码里，并不是一个独立完整的 relay 部署手册。

## 官方资料位置

- 官方安全模型说明：<https://paseo.sh/docs/security>
- 官方中文 README 的自托管 relay TLS 小节：<https://github.com/getpaseo/paseo/blob/main/README.zh-CN.md#自托管-relay-tls>
- 官方 relay 实现源码：<https://github.com/getpaseo/paseo/tree/main/packages/relay>
- 官方 Cloudflare Worker 配置：<https://github.com/getpaseo/paseo/blob/main/packages/relay/wrangler.toml>
- 官方 Docker 说明：<https://paseo.sh/docs/docker>

## 组件关系

Paseo 多端互联涉及三个角色：

- `daemon`：运行在你的服务器或容器里，负责 Web UI、工作区、agent CLI、任务执行。
- `relay`：中继服务，用于让客户端和 daemon 在不同网络下建立连接。
- `client`：浏览器、移动端或其他连接端。

默认安装客户端后会连到官方 `relay.paseo.sh`。自部署的目标是让 daemon 发布到你自己的 relay，例如 `relay.example.com:443`。

## 官方推荐配置项

官方 README 给出的 daemon 环境变量是：

```bash
PASEO_RELAY_ENDPOINT=127.0.0.1:8080 \
PASEO_RELAY_PUBLIC_ENDPOINT=relay.example.com:443 \
PASEO_RELAY_USE_TLS=true \
paseo daemon start
```

等价的 `config.json` 写法：

```json
{
  "daemon": {
    "relay": {
      "enabled": true,
      "endpoint": "127.0.0.1:8080",
      "publicEndpoint": "relay.example.com:443",
      "useTls": true
    }
  }
}
```

字段含义：

- `enabled`：启用自定义 relay。
- `endpoint`：daemon 实际连接的 relay 地址。若 relay 与 daemon 在同一台机器，可用 `127.0.0.1:8080`。
- `publicEndpoint`：客户端看到并使用的公网 relay 地址。
- `useTls`：公网地址是否使用 TLS。生产环境通常设置为 `true`。

## 当前仓库的 daemon 配置方式

当前仓库构建的是自定义 Paseo daemon 镜像，基础镜像是：

```dockerfile
FROM ghcr.io/getpaseo/paseo:latest
```

如果容器内用户目录挂载到宿主机的 `./paseo-home`，则配置文件可放在：

```text
./paseo-home/.paseo/config.json
```

示例：

```json
{
  "daemon": {
    "relay": {
      "enabled": true,
      "endpoint": "relay.example.com:443",
      "publicEndpoint": "relay.example.com:443",
      "useTls": true
    }
  }
}
```

也可以用环境变量方式配置：

```yaml
services:
  paseo:
    image: ghcr.io/<owner>/<repo>:latest
    restart: unless-stopped
    ports:
      - "6767:6767"
    environment:
      PASEO_PASSWORD: "change-me"
      PASEO_RELAY_ENDPOINT: "relay.example.com:443"
      PASEO_RELAY_PUBLIC_ENDPOINT: "relay.example.com:443"
      PASEO_RELAY_USE_TLS: "true"
    volumes:
      - ./paseo-home:/home/paseo
      - ./workspace:/workspace
```

## 路线 A：部署官方 Cloudflare Worker relay

官方 `packages/relay/wrangler.toml` 显示官方 relay 是 Cloudflare Worker / Durable Object 形态。要部署同一套官方实现，推荐用 Cloudflare Workers。

基本流程：

```bash
git clone https://github.com/getpaseo/paseo.git
cd paseo
npm install
cd packages/relay
npx wrangler login
npx wrangler deploy
```

部署前需要根据自己的 Cloudflare 账号修改 `packages/relay/wrangler.toml`，常见改动包括：

- `name`：改成自己的 Worker 名称，例如 `my-paseo-relay`。
- `routes`：改成自己的域名路由，例如 `relay.example.com/*`。
- `workers_dev`：如果先用 `*.workers.dev` 测试，可按 Cloudflare Worker 配置启用开发域名。

部署完成后，把 daemon 指到你的 Worker 域名：

```bash
PASEO_RELAY_ENDPOINT=relay.example.com:443
PASEO_RELAY_PUBLIC_ENDPOINT=relay.example.com:443
PASEO_RELAY_USE_TLS=true
```

如果先用 Cloudflare 自动分配的 Worker 域名，例如 `my-paseo-relay.<account>.workers.dev`，则 endpoint 填：

```bash
PASEO_RELAY_ENDPOINT=my-paseo-relay.<account>.workers.dev:443
PASEO_RELAY_PUBLIC_ENDPOINT=my-paseo-relay.<account>.workers.dev:443
PASEO_RELAY_USE_TLS=true
```

## 路线 B：用反向代理暴露 relay

如果 relay 监听本机 `127.0.0.1:8080`，官方 README 给出的思路是用 Nginx 代理 WebSocket 到公网域名。

示例：

```nginx
server {
    listen 443 ssl;
    server_name relay.example.com;

    ssl_certificate /path/to/fullchain.pem;
    ssl_certificate_key /path/to/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }
}
```

daemon 配置：

```bash
PASEO_RELAY_ENDPOINT=127.0.0.1:8080
PASEO_RELAY_PUBLIC_ENDPOINT=relay.example.com:443
PASEO_RELAY_USE_TLS=true
```

这个配置表示 daemon 走本机明文连接 relay，外部客户端走 `relay.example.com:443` 的 TLS 入口。

## 验证

检查 relay 健康状态：

```bash
curl https://relay.example.com/health
```

检查 daemon 是否读取到 relay 配置：

```bash
docker compose logs -f paseo
```

修改配置后重启 daemon：

```bash
docker compose restart paseo
```

如果仍然连到默认 `relay.paseo.sh`，优先检查：

- `config.json` 是否挂载到了容器内 Paseo 实际使用的 home 目录。
- 环境变量是否被 compose 正确传入。
- `endpoint` 是否是 daemon 能访问的地址。
- `publicEndpoint` 是否是客户端能访问的公网地址。
- `useTls` 是否和公网入口协议一致。

## 安全注意事项

- 对外暴露 daemon Web UI 时必须设置强 `PASEO_PASSWORD`。
- relay 只负责中继连接，不应该替代 daemon 认证。
- 生产环境建议使用 HTTPS/WSS，也就是 `PASEO_RELAY_USE_TLS=true`。
- 如果 relay 和 daemon 分开部署，防火墙只开放必要端口。
- 自定义镜像内含 agent CLI，工作区挂载目录要按最小权限管理。

## 推荐落地结构

当前仓库可保持只构建自定义 daemon 镜像；relay 部署放在独立基础设施仓库或 Cloudflare Worker 项目中管理。

建议目录职责：

- 本仓库：维护 `Dockerfile`、GitHub Actions、自定义 CLI 版本。
- 服务器 compose：部署 `paseo` daemon，并设置 relay 相关环境变量。
- Cloudflare Worker 或 relay 仓库：维护 relay 部署和域名。

