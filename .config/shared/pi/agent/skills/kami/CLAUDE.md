# Kami

Kaku(写代码) · Waza(练习惯) · **Kami(出文档)** 三部曲之一。
暖米纸底 + 油墨蓝点缀 + serif 主导层级 + 编辑级留白，覆盖 6 种文档模板。

## 文件结构

| 路径 | 用途 | 改动频率 |
|---|---|---|
| `SKILL.md` | Claude 路由规则 | 低 |
| `CHEATSHEET.md / .en.md` | 快速设计参考 | 低 |
| `references/design.md` | 设计语言规范（九条铁律） | 低 |
| `references/writing.md` | 文案规范 | 低 |
| `references/production.md` | WeasyPrint 踩坑 | 中 |
| `assets/templates/` | 6 种模板 × 2 语言 | 中 |
| `assets/demos/` | README 展示用 demo | 样式改后重新生成 |
| `scripts/build.py` | 生成 PDF/PNG/PPTX | 低 |
| `scripts/package-skill.sh` | 打包 Claude Desktop ZIP（排除大字体） | 低 |

## 验证

```bash
python3 scripts/build.py          # 生成全部
python3 scripts/build.py --check  # CSS 扫描 (rgba / 冷灰 / 行高)
```

期望页数: one-pager 1 / letter 1 / resume 2(严格) / long-doc 7±2 / portfolio 6±2 / slides 7±3

## Demo 截图

所有 demo PNG 统一尺寸 **1241×1754px**（单张 A4 portrait @ 150dpi）。

单页 / 多页文档 (one-pager / letter / resume / portfolio / long-doc): 取第 1 页:
```bash
pdftoppm -r 150 -f 1 -l 1 -png <pdf> /tmp/p && cp /tmp/p-1.png <target>.png
```

横向幻灯片 (slides): 取前 2 页，每页缩至 867px 高 + 20px gap = 1754px，补底色至 1241px 宽:
```bash
pdftoppm -r 150 -f 1 -l 2 -png <pdf> /tmp/sl
magick /tmp/sl-1.png -resize x867 /tmp/sl1.png
magick /tmp/sl-2.png -resize x867 /tmp/sl2.png
magick -size $(identify -format '%w' /tmp/sl1.png)x20 xc:'#f5f4ed' /tmp/gap.png
magick /tmp/sl1.png /tmp/gap.png /tmp/sl2.png -append /tmp/stacked.png
magick /tmp/stacked.png -gravity Center -background '#f5f4ed' -extent 1241x1754 <target>.png
```

## 改动规范

- 改样式: 改 `references/design.md` + 所有模板 `<style>` 对应变量，跑 build.py 确认页数不变
- 改内容: 保留 CSS 不动，只改 body，跑 build.py 验证
- 加新模板: copy 最近的模板 -> 保持与 design.md 一致 -> SKILL.md 加路由 -> demos/ 放 demo

## 高风险踩坑 (详见 production.md Part 4)

1. Tag rgba 双层矩形: 必须实色 hex
2. 薄 border + 圆角双圈: border < 1pt + border-radius 触发
3. 简历 2 页溢出: 字体 fallback / line-height / 字号动一点都会爆
4. break-inside 在 flex 失效: 要包一层 block wrapper
5. height: 100vh 在 @page 不准: 改用 mm 明确值
6. SVG marker orient="auto" 不生效: WeasyPrint 不旋转 marker
7. section 内文本不加 max-width: `.manifesto`、`.section-lede` 等内容文本应撑满 `.page` 容器宽度，不设 max-width。例外: `.type-sample` 和 `.footer .colophon` 窄是合理的。

## 发布流程

每次打 Release tag 后必须执行：

```bash
bash scripts/package-skill.sh        # 生成 dist/kami.zip（< 5MB，不含 TsangerJinKai TTF）
gh release upload <tag> dist/kami.zip -R tw93/kami
```

README 下载链接固定用 `releases/latest/download/kami.zip`，不含版本号，发布后无需手动替换。

## 字体

TsangerJinKai02-W04.ttf 是商业字体，商业用途需从 tsanger.cn 获取授权。
无字体时 fallback: Source Han Serif SC -> Noto Serif CJK SC -> Songti SC -> Georgia。
英文模板用 Newsreader serif。

Claude Desktop ZIP 不打包 TsangerJinKai TTF（体积 ~19MB/个，会触发上传限制）。Skill 在构建中文文档前会自动检测字体，缺失时从 jsDelivr 下载到 `assets/fonts/`，WeasyPrint 通过已有相对路径读取，无需改 HTML。
