// 利润表 / 现金流量表通用模板：单栏（项目 + 两期金额）
// 数据与格式由同目录 income.json（利润表）或 cashflow.json（现金流量表）提供
// 现金流量表编译时用：--input data=projects/finance/cashflow.json

#import "/lib.typ": company-header, num, report-init

#show: report-init
#set page(paper: "a4", margin: (x: 18mm, y: 16mm))
#set text(size: 9.5pt)

// ===== 通用样式函数（与 balance.typ 保持一致） =====

#let amt(n, d: 2) = if n == none { [] }
  else if n < 0 { [(#num(calc.abs(n), digits: d, math: false))] }
  else { [#num(n, digits: d, math: false)] }

#let cell(v, kind: "normal", al: left, bold: false) = {
  let st = if kind == "subtotal" { (top: 0.5pt, bottom: 0pt) }
    else if kind == "total" { (top: 0.75pt, bottom: 0.5pt) }
    else { (top: 0pt, bottom: 0pt) }
  table.cell(
    align: al,
    stroke: (left: none, right: none, top: st.top, bottom: st.bottom),
    text(weight: if bold { "bold" } else { "regular" })[#v],
  )
}

// 一栏三列；本模板两期金额字段名为 cur/prev
#let row3(r, k1, k2) = {
  let k = r.at("type", default: "normal")
  let b = k == "subtotal" or k == "total"
  (
    cell(r.name, k, left, b),
    cell(amt(r.at(k1, default: none)), k, right, b),
    cell(amt(r.at(k2, default: none)), k, right, b),
  )
}

#let group3(r) = (
  table.cell(
    colspan: 3,
    fill: rgb(238, 238, 238),
    align: left,
    stroke: (left: none, right: none, top: 0.5pt, bottom: 0pt),
    text(weight: "bold")[#r.name],
  ),
)


// ===== 入口 =====
#let main(data) = {
  company-header()
  v(-1em)
  align(center)[= #data.title]
  v(0.6em)
  grid(
    columns: (1fr, 1fr),
    align(left)[#data.date],
    align(right)[单位：#data.unit],
  )

  let cells = ()
  for r in data.rows {
    cells += if r.at("type", default: "") == "group" { group3(r) }
      else { row3(r, "cur", "prev") }
  }

  table(
    columns: (3fr, 1.5fr, 1.5fr),
    stroke: none,
    table.header(
      table.cell(stroke: (bottom: 0.5pt))[项目],
      table.cell(stroke: (bottom: 0.5pt))[#data.col1],
      table.cell(stroke: (bottom: 0.5pt))[#data.col2],
    ),
    ..cells,
  )
}

// ===== 数据源 =====
#let data_source = sys.inputs.at("data", default: "income.json")
#main(json(data_source))
