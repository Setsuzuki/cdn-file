# DemonSword的静态资源加速网站

本站利用 GitHub Pages 提供免费的静态资源托管服务，同时使用 Cloudflare CDN 加速和缓存功能，确保您能快速访问和加载资源。

## 网站功能

- **状态页面**: 提供实时系统状态信息，显示当前所有系统操作正常。
- **性能优化**: 利用 Cloudflare 提供的强大加速和缓存功能，提高资源加载速度，减少延迟。
- **国旗 API**: 通过 `cdn.yuanshen.ovh` 提供的国旗 API，您可以获取各个国家的 SVG 格式国旗图片。

## 使用示例

### 获取国旗

您可以使用以下链接获取特定国家的国旗：

- `https://cdn.yuanshen.ovh/static/flag/{ISO 3166 的国家码}.svg`

### 国旗 API 调用示例

| 国家    | 调用链接                                          |
|---------|---------------------------------------------------|
| 中国    | [https://cdn.yuanshen.ovh/static/flag/cn.svg](https://cdn.yuanshen.ovh/static/flag/cn.svg) |
| 日本    | [https://cdn.yuanshen.ovh/static/flag/jp.svg](https://cdn.yuanshen.ovh/static/flag/jp.svg) |
| 台湾    | [https://cdn.yuanshen.ovh/static/flag/tw.svg](https://cdn.yuanshen.ovh/static/flag/tw.svg) |

## 许可证

此项目使用 MIT 许可证。详情请参阅 [LICENSE](LICENSE)。

特别感谢 [GitHub Pages](https://pages.github.com/) 提供的免费静态资源托管服务以及 [Cloudflare](https://www.cloudflare.com/) 提供的 CDN 加速服务！

感谢您的访问和使用！