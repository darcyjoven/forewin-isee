#import "/lib.typ": company-header, negative, page-count, report-init, table-count, table-mark

// 报表常用设置初始化
#show: report-init
#set page(
  // 固定公司抬头
  header: company-header(),
  // 固定页脚页码
  footer: page-count(),
  // 固定横向
  flipped: true,
)

// 表头表单：key: value 键值对，每行 3 组，每组 = 标签 1 列 + 值 2 列（共 9 列）
#let form(data) = {
  // 字段显示名，未登记的字段直接显示 key
  let labels = (
    docno: "单据编号",
    dat: "日期",
    item: "品号",
    qty: "数量",
    stock: "库存",
  )
  let cells = ()
  for chunk in data.pairs().chunks(3) {
    for (key, value) in chunk {
      cells += (
        table.cell(stroke: none, [#labels.at(key, default: key)：]),
        table.cell(stroke: none, colspan: 2, [#value]),
      )
    }
    // 不足 3 组时用空占位补齐，保证每行都是 9 列
    for _ in range(3 - chunk.len()) {
      cells += (
        table.cell(stroke: none, []),
        table.cell(stroke: none, colspan: 2, []),
      )
    }
  }
  table.header(level: 1, ..cells)
}

#let title() = {
  table.header(
    level: 2,
    table.cell()[h1],
    [h2],
    [h3],
    [h4],
    [h5],
    [h6],
    [h7],
    [h8],
    [h9],
  )
}
// 小计：无底色，上方 0.5pt 单线（会计惯例：单线表示小计），首列标注“小计”，数值右对齐、负数加括号；去掉左右竖线
#let subtotal(rows) = {
  if type(rows) != array { rows = () }
  rows
    .map(row => {
      let values = (
        row.h1,
        row.h2,
        row.h3,
        row.h4,
        row.h5,
        row.h6,
        row.h7,
        row.h8,
        row.h9,
      )
      values
        .enumerate()
        .map(((i, v)) => {
          let numeric = type(v) == int or type(v) == float
          table.cell(
            if i == 0 {
              if v == none { [小计] } else { [#v 小计] }
            } else if numeric {
              negative(v)
            } else {
              [#v]
            },
            align: if numeric { right } else { left },
            stroke: (top: 0.5pt, left: none, right: none),
          )
        })
    })
    .flatten()
}

// 明细 + 小计：每组先输出 data 行，再输出 subtotal 行
#let detail(groups) = {
  if type(groups) != array { groups = () }
  let cells = ()
  for group in groups {
    cells += group
      .data
      .map(row => {
        let values = (
          row.h1,
          row.h2,
          row.h3,
          row.h4,
          row.h5,
          row.h6,
          row.h7,
          row.h8,
          row.h9,
        )
        values
          .enumerate()
          .map(((i, v)) => {
            let numeric = type(v) == int or type(v) == float
            table.cell(
              if numeric { negative(v) } else { [#v] },
              align: if numeric { right } else { left },
            )
          })
      })
      .flatten()
    cells += subtotal(group.subtotal)
  }
  cells
}
// 合计：无底色，上方 1pt 粗线、下方 0.5pt（会计惯例合计用双线，Typst 以粗线替代），加粗，首列标注“合计”；去掉左右竖线
#let total(rows) = {
  if type(rows) != array { rows = () }
  rows
    .map(row => {
      let values = (
        row.h1,
        row.h2,
        row.h3,
        row.h4,
        row.h5,
        row.h6,
        row.h7,
        row.h8,
        row.h9,
      )
      values
        .enumerate()
        .map(((i, v)) => {
          let numeric = type(v) == int or type(v) == float
          table.cell(
            strong(if i == 0 {
              if v == none { [合计] } else { [合计 #v] }
            } else if numeric {
              negative(v)
            } else {
              [#v]
            }),
            align: if numeric { right } else { left },
            stroke: (top: 1pt, bottom: 0.5pt, left: none, right: none),
          )
        })
    })
    .flatten()
}
#let footer(i) = {
  table.footer(
    // 接下页提示不加边框；末页内容为空，自然也不留边框
    table.cell(
      table-count(index: i),
      colspan: 9,
      align: right,
      inset: (x: 0pt, y: 0.4em),
      stroke: none,
    ),
  )
}

// 入口函数
#let main(data, i) = {
  // 1. logo 公司抬头 page 部分 设置
  // 4. table detail
  // 4.1 table subtotal
  // 6. table footer
  // 7. page 当前页码 page 部分设置

  // 本表起始页标记：footer 里据此计算本表（而非整份文档）的页数
  table-mark(index: i)

  table(
    columns: (1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr),
    // 2. form（无字段时整段省略，避免出现空表头行）
    ..(if data.form.len() > 0 { (form(data.form),) } else { () }),
    // 3. table title
    title(),
    // 4. table detail
    ..detail(data.detail),
    // 5. table total
    ..total(data.total),
    // 6. table footer：本表 当前页/总页数；后面还有内容时提示接下页
    footer(i),
  )
}

// 资料来源
#let data_source = sys.inputs.at("data", default: "table.json")
#let data = json(data_source)
#data.enumerate().map(((i, doc)) => main(doc, i)).join(pagebreak())
