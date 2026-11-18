#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
gen_table.py —— 【table 报表模块】根据 JSON 结构生成 Typst 表格报表模板（仅用标准库）

模块定位:
    本脚本只负责 table（表格）类报表模板的生成。后续若有其它报表模块
    （例如不含表格的文本/卡片式报表），可各自新建 gen_xxx.py 与本脚本
    并列放在 templates/ 目录，彼此独立、互不干扰。

用法:
    python3 templates/table/gen_table.py <输入.json> <输出.typ>
    或 cd 到 templates/table/ 后：python3 gen_table.py <输入.json> <输出.typ>

生成规则:
    * 只读取第一层数组的第一个对象来推断结构，其余数据不读取。
    * 表格列名取 detail[0].data[0] 的 key（无 detail 时取 total[0] 的 key）；
      表单字段取 form 的 key。两者都生成为可直接修改的常量。
    * form / detail / total / subtotal 缺失时，不生成对应区块。
    * 生成物在运行时通过 sys.inputs（--input data=xxx.json）读取真实数据。
    * 公司抬头、页眉页脚、接下页等固定部分全部包含，并用醒目注释标记，
      方便整块注释掉。
"""

import json
import os
import sys


def fail(message):
    print("错误: " + message, file=sys.stderr)
    sys.exit(1)


def tq(value):
    """生成 Typst 字符串字面量（正确转义引号、反斜杠等）。"""
    return json.dumps(value, ensure_ascii=False)


def load_schema(path):
    try:
        with open(path, "r", encoding="utf-8") as handle:
            raw = json.load(handle)
    except OSError as exc:
        fail("无法读取 JSON 文件: %s" % exc)
    except ValueError as exc:
        fail("JSON 格式错误: %s" % exc)

    if isinstance(raw, list):
        if not raw:
            fail("JSON 顶层数组为空，无法推断结构")
        doc = raw[0]
    elif isinstance(raw, dict):
        doc = raw
    else:
        fail("JSON 顶层必须是数组或对象")

    if not isinstance(doc, dict):
        fail("第一层数组的第一个元素必须是对象")

    form = doc.get("form")
    has_form = isinstance(form, dict) and len(form) > 0

    detail = doc.get("detail")
    has_detail = isinstance(detail, list) and len(detail) > 0
    group = detail[0] if has_detail and isinstance(detail[0], dict) else None
    has_subtotal = bool(
        group
        and isinstance(group.get("subtotal"), list)
        and len(group["subtotal"]) > 0
    )

    total = doc.get("total")
    has_total = isinstance(total, list) and len(total) > 0

    # 列名来源：明细首行优先，其次合计首行
    first_row = None
    if has_detail and group and isinstance(group.get("data"), list) and group["data"]:
        first_row = group["data"][0]
    elif has_total:
        first_row = total[0]
    if not isinstance(first_row, dict) or not first_row:
        fail("无法确定表格列：detail[0].data[0] 与 total[0] 均不可用")
    columns = list(first_row.keys())

    return {
        "columns": columns,
        "form_fields": list(form.keys()) if has_form else [],
        "has_form": has_form,
        "has_detail": has_detail,
        "has_subtotal": has_subtotal,
        "has_total": has_total,
    }


def generate(schema, default_json):
    L = []
    a = L.append

    # --- 头部说明 ---
    a("// 本文件由 gen_table.py 根据 JSON 结构自动生成，可直接手工修改。\n")
    a("// 固定部分已用【固定·可注释】标出；不需要抬头/页眉页脚/接下页时，\n")
    a("// 按各处说明把对应的行改成行注释（Typst 注释为 //）即可。\n\n")

    # --- 导入 ---
    a("// 【固定·可注释】按需删去不用的导入（接下页要 table-count / table-mark）\n")
    a('#import "/lib.typ": company-header, negative, page-count, report-init, table-count, table-mark\n\n')

    # --- 页面 ---
    a("// 【固定·可注释】页面：公司抬头 + 页眉页脚 + 横向\n")
    a("// 不需要抬头/页码时，注释掉下面 #show 与 #set page 两行\n")
    a("#show: report-init\n")
    a("#set page(\n  header: company-header(),\n  footer: page-count(),\n  flipped: true,\n)\n\n")

    # --- 列定义 ---
    a("// ===== 【可配置】表格列：title 取 JSON 的 key，可直接改成中文 =====\n")
    a("#let fields = (\n")
    for col in schema["columns"]:
        a("  (key: %s, title: %s, width: 1fr),\n" % (tq(col), tq(col)))
    a(")\n")
    a("#let widths = fields.map(field => field.width)\n")
    a("#let row-values(row) = fields.map(field => row.at(field.key, default: none))\n\n")

    # --- 表单字段 ---
    if schema["has_form"]:
        a("// ===== 【可配置】表单字段：(JSON 的 key, 标签)，标签默认同为 key =====\n")
        a("#let form-fields = (\n")
        for key in schema["form_fields"]:
            a("  (%s, %s),\n" % (tq(key), tq(key)))
        a(")\n\n")

        ncols = len(schema["columns"])
        # 每组至少占 2 列（标签 1 + 值 1）；每行最多 3 组，列少时自动减少组数
        groups_per_row = min(3, max(1, ncols // 2))
        per_group = max(2, ncols // groups_per_row)
        value_span = per_group - 1
        trailing = ncols - groups_per_row * per_group
        trailing_line = ""
        if trailing > 0:
            trailing_line = "    cells += (table.cell([], colspan: %d, stroke: none),)\n" % trailing
        form_tpl = """
// ===== 表单：每行 GPR 组（按列数自适应），标签右对齐、值左对齐并紧靠，整块无边框 =====
#let form(data) = {
  let cells = ()
  for chunk in form-fields.chunks(GPR) {
    for (key, label) in chunk {
      cells += (
        table.cell([#label：], align: right, inset: (right: 2pt), stroke: none),
        table.cell([#data.at(key, default: none)], colspan: VALUE_SPAN, align: left, inset: (left: 2pt), stroke: none),
      )
    }
    for _ in range(GPR - chunk.len()) {
      cells += (table.cell([], stroke: none), table.cell([], colspan: VALUE_SPAN, stroke: none))
    }
TRAILING_LINE  }
  table.header(level: 1, ..cells)
}

"""
        a(form_tpl.replace("VALUE_SPAN", str(value_span))
                   .replace("TRAILING_LINE", trailing_line)
                   .replace("GPR", str(groups_per_row)))

    # --- 表头 ---
    a("// ===== 表头：列名取 fields.title =====\n")
    a("#let title() = {\n  table.header(level: 2, ..fields.map(field => [#field.title]))\n}\n\n")

    # --- 小计 ---
    if schema["has_subtotal"]:
        a("""
// ===== 小计：上方 0.5pt 单线、无竖线、下方留 0.2em；首列“名称 小计” =====
#let subtotal(rows) = {
  if type(rows) != array { rows = () }
  rows
    .map(row => {
      let values = row-values(row)
      values
        .enumerate()
        .map(((i, value)) => {
          let numeric = type(value) == int or type(value) == float
          table.cell(
            if i == 0 {
              if value == none { [小计] } else { [#value 小计] }
            } else if numeric {
              negative(value)
            } else {
              [#value]
            },
            align: if numeric { right } else { left },
            stroke: (top: 0.5pt, left: none, right: none),
            inset: (bottom: 5pt + 0.2em),
          )
        })
    })
    .flatten()
}

""")

    # --- 合计 ---
    if schema["has_total"]:
        a("""
// ===== 合计：上方 0.75pt、下方 0.5pt、无竖线、整行加粗；首列“合计” =====
#let total(rows) = {
  if type(rows) != array { rows = () }
  rows
    .map(row => {
      let values = row-values(row)
      values
        .enumerate()
        .map(((i, value)) => {
          let numeric = type(value) == int or type(value) == float
          table.cell(
            strong(if i == 0 {
              if value == none { [合计] } else { [#value 合计] }
            } else if numeric {
              negative(value)
            } else {
              [#value]
            }),
            align: if numeric { right } else { left },
            stroke: (top: 0.75pt, bottom: 0.5pt, left: none, right: none),
          )
        })
    })
    .flatten()
}

""")

    # --- 明细 ---
    if schema["has_detail"]:
        a("""
// ===== 单行明细单元格：数值右对齐、负数加括号 =====
#let detail-row(row) = {
  row-values(row).map(value => {
    let numeric = type(value) == int or type(value) == float
    table.cell(
      if numeric { negative(value) } else { [#value] },
      align: if numeric { right } else { left },
    )
  })
}

""")
        if schema["has_subtotal"]:
            a("""
// ===== 明细：每组 data 行 + 小计；最后一行与小计绑成不可拆分块 =====
#let detail(groups) = {
  if type(groups) != array { groups = () }
  let cells = ()
  for group in groups {
    let rows = if type(group.data) == array { group.data } else { () }
    if rows.len() > 1 {
      for row in rows.slice(0, rows.len() - 1) {
        cells += detail-row(row)
      }
    }
    if rows.len() == 0 {
      cells += subtotal(group.subtotal)
    } else {
      cells += (table.cell(
        block(
          breakable: false,
          table(
            columns: widths,
            stroke: (left: 1pt, right: 1pt, top: none, bottom: none),
            ..detail-row(rows.last()),
            ..subtotal(group.subtotal),
          ),
        ),
        colspan: widths.len(),
        inset: 0pt,
        // 自画上下横线：相邻两组都只有一行明细时，两个外层单元格直接相接，
        // 若都为 none 则小计之后那一行没有上边框；左右竖线仍由内层表格画
        stroke: (top: 1pt, bottom: 1pt, left: none, right: none),
      ),)
    }
  }
  cells
}

""")
        else:
            a("""
// ===== 明细：仅 data 行（无小计） =====
#let detail(groups) = {
  if type(groups) != array { groups = () }
  let cells = ()
  for group in groups {
    let rows = if type(group.data) == array { group.data } else { () }
    for row in rows {
      cells += detail-row(row)
    }
  }
  cells
}

""")

    # --- 接下页（固定·可注释） ---
    a("""
// ===== 【固定·可注释】接下页提示（本表页次，跨页时显示“接下页”） =====
// 不需要时：注释掉本 footer 函数，以及 main 里的 table-mark(index: i) 与 footer(i)
#let footer(i) = {
  table.footer(
    repeat: true,
    table.cell(
      table-count(index: i),
      colspan: widths.len(),
      align: right,
      inset: (x: 0pt, y: 0.4em),
      stroke: none,
    ),
  )
}

""")

    # --- 入口 ---
    a("// ===== 入口：按存在区块组装表格 =====\n")
    a("#let main(data, i) = {\n")
    a("  // 【接下页·可注释】本表起始页标记\n")
    a("  table-mark(index: i)\n\n")
    a("  table(\n    columns: widths,\n")
    if schema["has_form"]:
        a("    // 表单\n    ..(if data.form.len() > 0 { (form(data.form),) } else { () }),\n")
    a("    // 表头\n    title(),\n")
    if schema["has_detail"]:
        a("    // 明细 + 小计\n    ..detail(data.detail),\n")
    if schema["has_total"]:
        a("    // 合计\n    ..total(data.total),\n")
    a("    // 【接下页·可注释】跨页提示\n    footer(i),\n")
    a("  )\n}\n\n")

    # --- 数据源 ---
    a("// ===== 数据源：编译时用 --input data=xxx.json 传入真实数据 =====\n")
    a('#let data_source = sys.inputs.at("data", default: %s)\n' % tq(default_json))
    a("#let data = json(data_source)\n")
    a("#data.enumerate().map(((i, doc)) => main(doc, i)).join(pagebreak())\n")

    return "".join(L)


def main(argv):
    if len(argv) == 2 and argv[1] in ("-h", "--help"):
        print("用法: python3 %s <输入.json> <输出.typ>" % os.path.basename(argv[0]))
        return 0
    if len(argv) != 3:
        print("用法: python3 %s <输入.json> <输出.typ>" % os.path.basename(argv[0]), file=sys.stderr)
        return 2

    json_path, out_path = argv[1], argv[2]
    schema = load_schema(json_path)
    content = generate(schema, os.path.basename(json_path))

    parent = os.path.dirname(os.path.abspath(out_path))
    if parent and not os.path.isdir(parent):
        os.makedirs(parent, exist_ok=True)
    try:
        with open(out_path, "w", encoding="utf-8") as handle:
            handle.write(content)
    except OSError as exc:
        fail("无法写入输出文件: %s" % exc)

    parts = []
    if schema["has_form"]:
        parts.append("form")
    if schema["has_detail"]:
        parts.append("detail")
    if schema["has_subtotal"]:
        parts.append("subtotal")
    if schema["has_total"]:
        parts.append("total")
    print("已生成: %s" % out_path)
    print("列(%d): %s" % (len(schema["columns"]), ", ".join(schema["columns"])))
    print("表单字段: %s" % (", ".join(schema["form_fields"]) or "无"))
    print("生成区块: %s" % ("、".join(parts) or "无"))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
