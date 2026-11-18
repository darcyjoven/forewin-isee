#import "/lib.typ": company-header, negative, page-count, report-init, table-count, table-mark

// ============ 页面 ============
#show: report-init
#set page(
  header: company-header(), // 固定公司抬头
  footer: page-count(), // 固定页脚页码
  flipped: true, // 固定横向
)

// ============ 列定义 ============
// (key, title, width)：顺序即列顺序，增删列、改表头、单独调某列宽度都只动这一处
#let fields = (
  (key: "h1", title: "h1", width: 1fr),
  (key: "h2", title: "h2", width: 1fr),
  (key: "h3", title: "h3", width: 1fr),
  (key: "h4", title: "h4", width: 1fr),
  (key: "h5", title: "h5", width: 1fr),
  (key: "h6", title: "h6", width: 1fr),
  (key: "h7", title: "h7", width: 1fr),
  (key: "h8", title: "h8", width: 1fr),
  (key: "h9", title: "h9", width: 1fr),
)
// 表格列宽，按上面的定义顺序取出
#let widths = fields.map(field => field.width)

// 取一行的 9 个值（缺失字段为 none），只统一取数，不涉及样式
#let row-values(row) = fields.map(field => row.at(field.key, default: none))

// ============ 表单字段 ============
// (key, 显示名)：顺序决定表单排列顺序，每行 3 组；新增字段在这里登记
#let form-fields = (
  ("docno", "docno"),
  ("dat", "dat"),
  ("item", "item"),
  ("qty", "qty"),
  ("stock", "stock"),
)

// ============ 表单（key: value） ============
// 每行 3 组，每组 = 标签 1 列 + 值 2 列；标签右对齐、值左对齐并紧靠，整块无边框
#let form(data) = {
  let cells = ()
  for chunk in form-fields.chunks(3) {
    for (key, label) in chunk {
      cells += (
        table.cell(
          [#label：],
          align: right,
          inset: (right: 2pt),
          stroke: none,
        ),
        table.cell(
          [#data.at(key, default: none)],
          colspan: 2,
          align: left,
          inset: (left: 2pt),
          stroke: none,
        ),
      )
    }
    // 不足 3 组时补空占位，保证每行都是整列数
    for _ in range(3 - chunk.len()) {
      cells += (table.cell([], stroke: none), table.cell([], colspan: 2, stroke: none))
    }
  }
  table.header(level: 1, ..cells)
}

// ============ 表头 ============
#let title() = {
  table.header(level: 2, ..fields.map(field => [#field.title]))
}

// ============ 小计 ============
// 上方 0.5pt 单线（会计惯例单线表示小计），无竖线，首列“名称 小计”，下方留 0.2em
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

// ============ 合计 ============
// 上方 0.75pt、下方 0.5pt，无竖线，整行加粗，首列“合计”
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

// ============ 明细 ============
// 单行明细的单元格（普通样式）
#let detail-row(row) = {
  let values = row-values(row)
  values.map(value => {
    let numeric = type(value) == int or type(value) == float
    table.cell(
      if numeric { negative(value) } else { [#value] },
      align: if numeric { right } else { left },
    )
  })
}

// 按组输出：data 行之后紧跟该组小计
// 每组的最后一行明细与该组小计包进同一个不可拆分块，
// 页尾放不下小计时，最后一行会跟着一起移到下一页，避免小计单独出现在页首
#let detail(groups) = {
  if type(groups) != array { groups = () }
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
      // 最后一行 + 小计：整块不可拆分
      // 内层表格只画左右竖线，上下横线交给相邻行，避免与外层边框叠成粗线
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
        stroke: none,
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

  table(
    columns: widths,
    // 表单（无字段时整段省略，避免出现空表头行）
    ..(if data.form.len() > 0 { (form(data.form),) } else { () }),
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
