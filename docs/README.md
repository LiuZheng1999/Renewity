# GitHub Pages 法律文档

这个 `docs/` 目录可以直接作为 GitHub Pages 站点发布，内容与应用内《隐私政策》《使用条款》一致。

## 发布步骤

1. 把仓库推送到 GitHub（建议仓库名 `Renewity`）。
2. 打开仓库 **Settings → Pages**。
3. Build and deployment 选 **Deploy from a branch**。
4. Branch 选 `main`，文件夹选 `/docs`，保存。
5. 几分钟后打开：`https://liuzheng1999.github.io/Renewity/`

如果 GitHub 用户名不是 `LiuZheng1999`，或仓库名不是 `Renewity`，请同时改：

- `Renewity/Utilities/AppConfig.swift` 里的 `legalWebsiteURL`
- `Renewity/Legal/` 下各语言文档中的网址
- 然后重新运行 `python3 scripts/build_legal_pages.py`

应用「关于」页的「隐私政策（网页）」「使用条款（网页）」会打开上述地址。
