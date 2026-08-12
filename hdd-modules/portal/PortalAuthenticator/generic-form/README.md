# (A) 通用表单解析器

抓登录页 → 自动解析 username/password 输入框 → POST 账号密码 → 按"成功标记"验证。

- 纯 shell + curl，零依赖，适合普通 HTML 表单门户
- 遇到 JS 加密 / 动态 token 的门户会卡，预留 hook 扩展点（刷机后针对性补）
- 配置：URL / 字段名 / 成功标记 / UA（`portal.conf`）

状态：骨架占位，刷机后按实际门户填充。
