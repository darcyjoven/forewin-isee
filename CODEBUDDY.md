# CODEBUDDY.md

This file provides guidance to CodeBuddy Code when working with code in this repository.

## 项目概述

ISEE 是一个基于 [Typst](https://github.com/typst/typst) 的 PDF 报表系统：模板是 `.typ` 文件，数据通过 JSON 传入，用于替代水晶报表等商业方案。仓库根目录是使用者自己的工作区（可自由修改），`isee-core/` 是独立的核心库 submodule（**不要在此目录内修改**）。

## 常用命令

编译一个报表（`--root` 必须是仓库根目录，因为所有模板都使用 `/lib.typ` 这类绝对导入）：

```bash
typst compile \
  --root . \
  --font-path isee-core/fonts --font-path fonts \
  projects/inventory/cimr500/main.typ \
  out/cimr500.pdf \
  --input data=projects/inventory/cimr500/data.json
```

开发时的其他方式：

```bash
typst watch projects/inventory/cimr500/main.typ out.pdf   # 增量编译预览
typst compile tests/table.typ                              # 渲染视觉测试文件
typst compile isee-core/styles/fonts.typ                    # 渲染 core 组件的自示例页
```

- 本机没有安装 `typst` CLI，日常开发依赖 VS Code 的 **Tinymist** 插件（自带 typst，提供预览 / 导出 PDF 按钮）。生产编译才需要官方二进制。
- 项目**没有**自动化测试框架或 lint 命令。`tests/*.typ` 是需要人工打开预览的视觉测试页（`base.typ` 列出各类单据形态，`document.typ`、`table.typ`、`chart.typ`、`label.typ` 各覆盖一类控件）。
- 字体：`isee-core/fonts/` 不进版本库，需从 [fonts.zip](https://github.com/darcyjoven/isee-attachment/releases/latest/download/fonts.zip) 解压；根目录 `fonts/` 放自定义字体（`fonts/*` 被 gitignore，仅保留 `download.sh`）。字体缺失时 Typst 会静默回退，不报错。
- 第三方包版本固定在源码 import 中（`ctyp 0.3.1`、`cuti 0.3.0`、`zero 0.7.0`、`zh-kit 0.1.0`、`lilaq 0.6.0`、`tiaoma 0.3.0`、`suiji 0.5.1` 等）。离线生产环境需把 `~/.cache/typst/packages/preview` 整体复制过去。

## 架构

```
lib.typ                 根入口：转发 isee-core/lib.typ + 定义项目级 report-init / code-init
config.typ              company.name / company.logo，被 company-header 默认使用
isee-core/              核心库 submodule，只读
  lib.typ               汇总导出所有 styles + components，文件末尾即 core 的演示文档
  styles/fonts.typ      字体名常量（song/hei/kai/mono...）、混合字体（financial/formal/bussiness/code）、ctypset 全局排版
  styles/number.typ     数字与金额格式化（num 来自 @preview/zero，中文数字来自 zh-kit）
  components/           company-header、page_count、count(row-count/table-count/table-mark)、truncate、wrap
  scaffold/             根目录骨架文件的脱敏版本，由 isee 的 init.sh 复制生成
  docs/                 README.typ（项目说明/部署）、INSTALL.md（安装）
projects/<domain>/<报表编号>/
  main.typ              报表模板
  *.json                对应的数据文件（带随机后缀的是临时数据）
templates/              新报表骨架：table.typ 多页表格骨架，demo/ 为一个完整示例
```

### 数据流与模板约定

- 数据文件通过 `sys.inputs` 传入，模板底部形如：
  ```typst
  #let data_source = sys.inputs.at("data", default: "data.0jITA.json")
  #let data = json(data_source)
  #main(data)
  ```
  编译时始终显式传 `--input data=...`，不要依赖模板里的随机默认文件名。
- 报表主体写成 `#let main(data) = { ... }` 函数，顶部用 `#show: report-init` 初始化页面/数字/字体，再用 `set page` 按报表需要覆盖纸张尺寸（如 `width: 297mm, height: auto` 做自适应宽度的横向表）。
- 金额/数量统一走 `num(n, digits: d, group: ..., round: ..., math: false)`。`set-num` / `set-group` / `set-round` 是全局默认值，且只对 `num()` 生效，对裸数字无效。
- 明细列表用 `#grid`/`table` + `.map(row => (...)).flatten()`；多单据合成一个 PDF 用 `#data.map(render).join(pagebreak())`（见 `templates/table.typ`、`templates/demo/main.typ`）。

### 根目录与 core 的对应关系

`assets`、`components`、`fonts`、`styles`、`lib.typ` 在根目录和 `isee-core/` 下都存在：core 里是通用实现，根目录同名位置是给使用者的扩展插槽。自定义样式和组件应放在**根目录**并在 `/lib.typ` 里追加导入后再使用。

注意本工作副本的 submodule 目录名是 `isee-core`（根 `lib.typ` 导入 `/isee-core/lib.typ`），而 `isee-core/scaffold/lib.typ` 与文档里写的是 `/core/lib.typ`——以当前仓库实际的 `isee-core/` 为准。此副本也没有 `init.sh` / `init.ps1`，骨架文件已初始化完毕，不需要再执行。

### 关键组件行为

- `company-header()` 读取 `/config.typ` 的 `company`，同时 `isee-core/components/header.typ` 也导入了 `isee-core/config.typ` 作为回退；真实公司名与 logo 只改根目录 `config.typ`。
- `page-count(fill: (current, total) => ...)` 在表格 header/footer 内也可用；`row-count(id:, index:)` 依赖正文里的 `#metadata((id: "detail", row: n))` 标记计数，适合跨页续表的"第 N 项"。
- `truncate(str, suffix: "…")` 按单元格可用宽度二分截断（支持中文），`wrap(str)` 为拉丁长串插入零宽断点，解决凭证单元格里英文规格溢出。
- `report-init` 已设置 `ctypset`（中文宋体、拉丁黑体）与伪粗体，模板内再 `set text(font: bussiness)` 之类即可覆盖。
