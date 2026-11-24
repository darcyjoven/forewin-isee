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
      表单字段取 form 的 key。列数在生成时固定，表头、明细、小计、合计、表单
      均按列/按字段逐条写出，便于对单列单独调整样式。
    * form / detail / total / subtotal 缺失时，不生成对应区块。
    * 单元格垂直对齐统一为 horizon（基线对齐）：同一行内容落在同一条基线上，
      某列换成多行时其余单元格处在行的垂直中部，不会全挤在行顶、行底留空。
      需要贴顶 / 贴底时，把生成结果里的 + horizon 换成 + top / + bottom。
    * 无小计时，数字列用 format-table 做小数点对齐（纯对齐：不加千分位、
      不做舍入，按原值显示）；有小计时明细会包成嵌套表格，对齐会乱，故不做。
    * 生成物在运行时通过 sys.inputs（--input data=xxx.json）读取真实数据；
      data 默认值是输入 JSON 相对于项目根目录的路径，用 Typst 根相对写法
      （以 / 开头，与模板里的 /lib.typ 一致），因此与 .typ 文件放在哪里无关。
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


def find_project_root(start):
    """从起始目录逐级向上找项目根目录：含 .git 或 CODEBUDDY.md 的第一层。"""
    current = os.path.abspath(start)
    while True:
        if (os.path.exists(os.path.join(current, ".git"))
                or os.path.exists(os.path.join(current, "CODEBUDDY.md"))):
            return current
        parent = os.path.dirname(current)
        if parent == current:
            return None
        current = parent


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
    # 由脚本按首行值的类型决定该列对齐方式，模板里不再做运行时类型判断
    numeric = [
        isinstance(first_row[col], (int, float)) and not isinstance(first_row[col], bool)
        for col in columns
    ]

    return {
        "columns": columns,
        "numeric": numeric,
        "form_fields": list(form.keys()) if has_form else [],
        "has_form": has_form,
        "has_detail": has_detail,
        "has_subtotal": has_subtotal,
        "has_total": has_total,
    }


def generate(schema, default_data):
    L = []
    a = L.append
    columns = schema["columns"]
    numeric = schema["numeric"]

    # --- 头部说明 ---
    a("// 本文件由 gen_table.py 根据 JSON 结构自动生成，可直接手工修改。\n")
    a("// 固定部分已用【固定·可注释】标出；不需要抬头/页眉页脚/接下页时，\n")
    a("// 按各处说明把对应的行改成行注释（Typst 注释为 //）即可。\n\n")

    # --- 导入 ---
    imports = ["company-header", "page-count", "report-init", "table-count", "table-mark"]
    # 无小计时才做小数点对齐：有小计的明细是嵌套表格，会让对齐错乱
    align_numbers = any(numeric) and not schema["has_subtotal"]
    if align_numbers:
        imports.append("format-table")
    a("// 【固定·可注释】按需删去不用的导入（接下页要 table-count / table-mark）\n")
    a('#import "/lib.typ": %s\n\n' % ", ".join(imports))

    # --- 页面 ---
    a("// 【固定·可注释】页面：公司抬头 + 页眉页脚 + 横向\n")
    a("// 不需要抬头/页码时，注释掉下面 #show 与 #set page 两行\n")
    if schema["has_form"]:
        a("// 表单值末尾拼一个空 box，避免值被当作数字解析；\n")
        a("// 并保留单元格的 colspan（否则表格头排版会散）\n")
        a("#let form-val(v) = [#v#box[]]\n\n")
    a("#show: report-init\n")
    a("#set page(\n  header: company-header(),\n  footer: page-count(),\n  flipped: true,\n)\n\n")

    # --- 垂直对齐 ---
    a("// ===== 【可配置】垂直对齐：所有单元格统一 horizon（基线对齐） =====\n")
    a("// 某列换成多行时，其余单元格处在行的垂直中部，不会全挤在行顶；\n")
    a("// 想改成贴顶 / 贴底，把下面所有 + horizon 换成 + top / + bottom\n\n")

    # --- 小数点对齐（仅无小计时） ---
    if align_numbers:
        a("// ===== 数字列小数点对齐（仅无小计时；有小计的明细为嵌套表格，不做）=====\n")
        a("// 纯对齐：不加千分位、不做舍入，数字按原值显示\n")
        a("#let num-align = (math: false, group: (threshold: 999))\n")
        a("#show table: format-table(\n")
        a("  " + ", ".join("num-align" if n else "none" for n in numeric) + ",\n")
        a(")\n\n")

    # --- 列宽 ---
    a("// ===== 【可配置】表格列宽：有几列写几列，逐列调整 =====\n")
    a("#let widths = (")
    a(", ".join("1fr" for _ in columns))
    a(")\n\n")

    # --- 表单 ---
    if schema["has_form"]:
        ncols = len(columns)
        # 每组至少占 2 列（标签 1 + 值 1）；每行最多 3 组，列少时自动减少组数
        groups_per_row = min(3, max(1, ncols // 2))
        per_group = max(2, ncols // groups_per_row)
        value_span = per_group - 1
        trailing = ncols - groups_per_row * per_group
        fields = schema["form_fields"]

        a("// ===== 表单：逐字段写出，标签右对齐、值左对齐并紧靠，整块无边框 =====\n")
        a("#let form(data) = table.header(\n  level: 1,\n")
        for start in range(0, len(fields), groups_per_row):
            chunk = fields[start:start + groups_per_row]
            for key in chunk:
                a('  table.cell(text(%s), align: right + horizon, inset: (right: 2pt), stroke: none),\n' % tq(key + "："))
                a('  table.cell(form-val(data.%s), colspan: %d, align: left + horizon, inset: (left: 2pt), stroke: none),\n' % (key, value_span))
            # 不足一组时补空占位，保证每行都是整列数
            for _ in range(groups_per_row - len(chunk)):
                a("  table.cell([], stroke: none),\n")
                a("  table.cell([], colspan: %d, stroke: none),\n" % value_span)
            # 列数除不尽时，每行末尾补足剩余列
            if trailing > 0:
                a("  table.cell([], colspan: %d, stroke: none),\n" % trailing)
        a(")\n\n")

    # --- 表头 ---
    a("// ===== 表头：逐列写出，单独改某列表头样式直接改对应单元格 =====\n")
    a("#let title() = table.header(\n  level: 2,\n")
    for col in schema["columns"]:
        a("  table.cell(text(%s), align: left + horizon),\n" % tq(col))
    a(")\n\n")

    # --- 小计 ---
    if schema["has_subtotal"]:
        first = columns[0]
        a("// ===== 小计：首列“名称 小计”，其余逐列写出；不画竖线，只画横线 =====\n")
        a("#let subtotal(rows) = {\n")
        a("  rows.map(row => (\n")
        a("    table.cell([#row.%s 小计], align: left + horizon, inset: (bottom: 5pt + 0.2em), stroke: (top: 1pt, bottom: 1pt, left: none, right: none)),\n" % first)
        rest = columns[1:]
        stroke = "(top: 1pt, bottom: 1pt, left: none, right: none)"
        for col, is_num in zip(rest, numeric[1:]):
            val = "[#row.%s]" % col
            a("    table.cell(%s, align: %s + horizon, inset: (bottom: 5pt + 0.2em), stroke: %s),\n" % (val, "right" if is_num else "left", stroke))
        a("  )).flatten()\n")
        a("}\n\n")

    # --- 合计 ---
    if schema["has_total"]:
        first = columns[0]
        a("// ===== 合计：首列“合计”，其余逐列写出，整行加粗；竖线同小计，不画 =====\n")
        a("#let total(rows) = {\n")
        a("  rows.map(row => (\n")
        a("    table.cell(strong([#row.%s 合计]), align: left + horizon, stroke: (top: 1pt, bottom: 1pt, left: none, right: none)),\n" % first)
        rest = columns[1:]
        stroke = "(top: 1pt, bottom: 1pt, left: none, right: none)"
        for col, is_num in zip(rest, numeric[1:]):
            val = "[#row.%s]" % col
            a("    table.cell(%s, align: %s + horizon, stroke: %s),\n" % (val, "right" if is_num else "left", stroke))
        a("  )).flatten()\n")
        a("}\n\n")

    # --- 明细 ---
    if schema["has_detail"]:
        a("// ===== 单行明细：逐列写出，单独改某列样式直接改对应单元格 =====\n")
        a("#let detail-row(row) = (\n")
        for col, is_num in zip(columns, numeric):
            val = "[#row.%s]" % col
            a("  table.cell(%s, align: %s + horizon),\n" % (val, "right" if is_num else "left"))
        a(")\n\n")
        if schema["has_subtotal"]:
            a("""
// ===== 明细：每组 data 行 + 小计；最后一行与小计绑成不可拆分块（外层只画横线） =====
#let detail(groups) = {
  let cells = ()
  for group in groups {
    let rows = group.data
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
            stroke: 1pt + black,
            ..detail-row(rows.last()),
            ..subtotal(group.subtotal),
          ),
        ),
        colspan: widths.len(),
        inset: 0pt,
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
  let cells = ()
  for group in groups {
    let rows = group.data
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
    # 合计行号 = 表单行数 + 表头 1 行 + 明细行数（每组最后一行与小计合并为 1 行）
    if schema["has_form"]:
        ncols = len(columns)
        groups_per_row = min(3, max(1, ncols // 2))
        form_rows = (len(schema["form_fields"]) + groups_per_row - 1) // groups_per_row
    else:
        form_rows = 0
    detail_expr = "data.detail.map(g => g.data.len()).sum()" if schema["has_detail"] else "0"

    a("// ===== 入口：按存在区块组装表格 =====\n")
    a("#let main(data, i) = {\n")
    a("  // 【接下页·可注释】本表起始页标记\n")
    a("  table-mark(index: i)\n\n")
    if schema["has_total"]:
        a("  // 对合计整行加粗\n")
        a("  let total-y = %d + 1 + %s\n" % (form_rows, detail_expr))
        a("  show table.cell: it => {\n")
        a("    if it.y == total-y and it.body.func() != strong {\n")
        a("      table.cell(strong(it.body), align: it.align, x: it.x, y: it.y, inset: it.inset, stroke: it.stroke)\n")
        a("    } else { it }\n")
        a("  }\n\n")
    a("  table(\n    columns: widths,\n    stroke: 1pt + black,\n")
    if schema["has_form"]:
        a("    // 表单\n    form(data.form),\n")
    a("    // 表头\n    title(),\n")
    if schema["has_detail"]:
        a("    // 明细 + 小计\n    ..detail(data.detail),\n")
    if schema["has_total"]:
        a("    // 合计\n    ..total(data.total),\n")
    a("    // 【接下页·可注释】跨页提示\n    footer(i),\n")
    a("  )\n}\n\n")

    # --- 数据源 ---
    a("// ===== 数据源：默认值为项目根相对路径；编译时可用 --input data=xxx.json 覆盖 =====\n")
    a('#let data_source = sys.inputs.at("data", default: %s)\n' % tq(default_data))
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

    # 默认数据路径相对项目根目录，并用 Typst 的根相对写法（/ 开头）
    root = find_project_root(os.path.dirname(os.path.abspath(__file__)))
    if root is None:
        fail("无法识别项目根目录（向上未找到 .git 或 CODEBUDDY.md）")
    json_abs = os.path.abspath(json_path)
    data_rel = os.path.relpath(json_abs, root).replace(os.sep, "/")
    if data_rel.startswith(".."):
        # 数据不在项目内时退回相对 .typ 的路径，避免 /../ 越出 root
        data_rel = os.path.relpath(json_abs, os.path.dirname(os.path.abspath(out_path))).replace(os.sep, "/")
        default_data = data_rel
    else:
        default_data = "/" + data_rel
    content = generate(schema, default_data)

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
