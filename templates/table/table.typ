#import "/lib.typ": company-header, page-count, report-init, table-count, table-mark

// ============ 页面 ============
#show: report-init
#set page(
  header: company-header(), // 固定公司抬头
  footer: page-count(), // 固定页脚页码
  flipped: true, // 固定横向
)

// 表单值末尾拼一个空 box，避免值被当作数字解析，
// 并保留单元格的 colspan（否则表格头排版会散）
#let form-val(v) = [#v#box[]]

// ============ 列宽 ============
// 有几列写几列；单独调某列宽度只改这里对应的一项
// 增删列时，同步修改 form / title / subtotal / total / detail-row 中对应的单元格
#let widths = (1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr)

// ============ 垂直对齐 ============
// 各处单元格统一用 horizon（基线对齐）：同一行的内容落在同一条基线上，
// 某列换成多行时，其余单元格自动处在行的垂直中部，不会全挤在行顶、行底留一大块空白。
// 想改成贴顶 / 贴底，把下面所有 + horizon 换成 + top / + bottom 即可

// ============ 表单（key: value） ============
// 每行 3 组，每组 = 标签 1 列 + 值 2 列；标签右对齐、值左对齐并紧靠，整块无边框
// 逐字段写出，某个字段要单独改样式或调顺序，直接改对应两行
#let form(data) = table.header(
  level: 1,
  table.cell(text("docno："), align: right + horizon, inset: (right: 2pt), stroke: none),
  table.cell(form-val(data.docno), colspan: 2, align: left + horizon, inset: (left: 2pt), stroke: none),
  table.cell(text("dat："), align: right + horizon, inset: (right: 2pt), stroke: none),
  table.cell(form-val(data.dat), colspan: 2, align: left + horizon, inset: (left: 2pt), stroke: none),
  table.cell(text("item："), align: right + horizon, inset: (right: 2pt), stroke: none),
  table.cell(form-val(data.item), colspan: 2, align: left + horizon, inset: (left: 2pt), stroke: none),
  table.cell(text("qty："), align: right + horizon, inset: (right: 2pt), stroke: none),
  table.cell(form-val(data.qty), colspan: 2, align: left + horizon, inset: (left: 2pt), stroke: none),
  table.cell(text("stock："), align: right + horizon, inset: (right: 2pt), stroke: none),
  table.cell(form-val(data.stock), colspan: 2, align: left + horizon, inset: (left: 2pt), stroke: none),
  // 不足 3 组时补空占位，保证每行都是整列数
  table.cell([], stroke: none),
  table.cell([], colspan: 2, stroke: none),
)

// ============ 表头 ============
// 逐列写出；改表头文字或单独加样式，直接改对应单元格
#let title() = table.header(
  level: 2,
  table.cell(text("h1"), align: left + horizon),
  table.cell(text("h2"), align: left + horizon),
  table.cell(text("h3"), align: left + horizon),
  table.cell(text("h4"), align: left + horizon),
  table.cell(text("h5"), align: left + horizon),
  table.cell(text("h6"), align: left + horizon),
  table.cell(text("h7"), align: left + horizon),
  table.cell(text("h8"), align: left + horizon),
  table.cell(text("h9"), align: left + horizon),
)

// ============ 小计 ============
// 首列“名称 小计”，其余逐列写出；对齐方式由 gen_table.py 按 JSON 值类型决定
// 不画任何竖线；横线为 1pt
#let subtotal(rows) = {
  rows.map(row => (
    table.cell([#row.h1 小计], align: left + horizon, inset: (bottom: 5pt + 0.2em), stroke: (top: 1pt, bottom: 1pt, left: none, right: none)),
    table.cell([#row.h2], align: left + horizon, inset: (bottom: 5pt + 0.2em), stroke: (top: 1pt, bottom: 1pt, left: none, right: none)),
    table.cell([#row.h3], align: right + horizon, inset: (bottom: 5pt + 0.2em), stroke: (top: 1pt, bottom: 1pt, left: none, right: none)),
    table.cell([#row.h4], align: left + horizon, inset: (bottom: 5pt + 0.2em), stroke: (top: 1pt, bottom: 1pt, left: none, right: none)),
    table.cell([#row.h5], align: right + horizon, inset: (bottom: 5pt + 0.2em), stroke: (top: 1pt, bottom: 1pt, left: none, right: none)),
    table.cell([#row.h6], align: right + horizon, inset: (bottom: 5pt + 0.2em), stroke: (top: 1pt, bottom: 1pt, left: none, right: none)),
    table.cell([#row.h7], align: left + horizon, inset: (bottom: 5pt + 0.2em), stroke: (top: 1pt, bottom: 1pt, left: none, right: none)),
    table.cell([#row.h8], align: left + horizon, inset: (bottom: 5pt + 0.2em), stroke: (top: 1pt, bottom: 1pt, left: none, right: none)),
    table.cell([#row.h9], align: left + horizon, inset: (bottom: 5pt + 0.2em), stroke: (top: 1pt, bottom: 1pt, left: none, right: none)),
  )).flatten()
}

// ============ 合计 ============
// 首列“合计”，其余逐列写出，整行加粗；竖线同小计，不画
#let total(rows) = {
  rows.map(row => (
    table.cell(strong([#row.h1 合计]), align: left + horizon, stroke: (top: 1pt, bottom: 1pt, left: none, right: none)),
    table.cell([#row.h2], align: left + horizon, stroke: (top: 1pt, bottom: 1pt, left: none, right: none)),
    table.cell([#row.h3], align: right + horizon, stroke: (top: 1pt, bottom: 1pt, left: none, right: none)),
    table.cell([#row.h4], align: left + horizon, stroke: (top: 1pt, bottom: 1pt, left: none, right: none)),
    table.cell([#row.h5], align: right + horizon, stroke: (top: 1pt, bottom: 1pt, left: none, right: none)),
    table.cell([#row.h6], align: right + horizon, stroke: (top: 1pt, bottom: 1pt, left: none, right: none)),
    table.cell([#row.h7], align: left + horizon, stroke: (top: 1pt, bottom: 1pt, left: none, right: none)),
    table.cell([#row.h8], align: left + horizon, stroke: (top: 1pt, bottom: 1pt, left: none, right: none)),
    table.cell([#row.h9], align: left + horizon, stroke: (top: 1pt, bottom: 1pt, left: none, right: none)),
  )).flatten()
}

// ============ 明细 ============
// 单行明细：逐列写出，单独改某列样式直接改对应行
#let detail-row(row) = (
  table.cell([#row.h1], align: left + horizon),
  table.cell([#row.h2], align: left + horizon),
  table.cell([#row.h3], align: right + horizon),
  table.cell([#row.h4], align: left + horizon),
  table.cell([#row.h5], align: right + horizon),
  table.cell([#row.h6], align: right + horizon),
  table.cell([#row.h7], align: left + horizon),
  table.cell([#row.h8], align: left + horizon),
  table.cell([#row.h9], align: left + horizon),
)

// 按组输出：data 行之后紧跟该组小计
// 每组的最后一行明细与该组小计包进同一个不可拆分块，
// 页尾放不下小计时，最后一行会跟着一起移到下一页，避免小计单独出现在页首
#let detail(groups) = {
  let cells = ()
  for group in groups {
    let rows = group.data
    // 除最后一行外的明细，正常参与分页
    if rows.len() > 1 {
      for row in rows.slice(0, rows.len() - 1) {
        cells += detail-row(row)
      }
    }
    if rows.len() == 0 {
      // 没有明细时小计照常输出
      cells += subtotal(group.subtotal)
    } else {
      // 最后一行 + 小计：整块不可拆分；外层只画横线，竖线交给内层各行自己决定
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

// ============ 表格页脚 ============
// 跨页时右下角提示“接下页（n/m）”，末页为空；不画边框
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

// ============ 入口 ============
#let main(data, i) = {
  // 本表起始页标记：供 footer 计算本表（而非整份文档）的页数
  table-mark(index: i)

  // 合计行号 = 表单行数 + 表头 1 行 + 明细行数（每组最后一行与小计合并为 1 行）
  // 对合计整行加粗
  let total-y = 2 + 1 + data.detail.map(g => g.data.len()).sum()
  show table.cell: it => {
    if it.y == total-y and it.body.func() != strong {
      table.cell(strong(it.body), align: it.align, x: it.x, y: it.y, inset: it.inset, stroke: it.stroke)
    } else { it }
  }

  table(
    columns: widths,
    // 所有边框统一为 1pt 黑色
    stroke: 1pt + black,
    // 表单（无字段时整段省略，避免出现空表头行）
    form(data.form),
    // 表头
    title(),
    // 明细 + 小计
    ..detail(data.detail),
    // 合计
    ..total(data.total),
    // 页脚：本表页次 / 接下页
    footer(i),
  )
}

// ============ 数据源 ============
#let data_source = sys.inputs.at("data", default: "table.json")
#let data = json(data_source)
#data.enumerate().map(((i, doc)) => main(doc, i)).join(pagebreak())
