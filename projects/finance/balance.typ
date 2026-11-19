// 资产负债表模板：左右双栏（左=资产，右=负债和所有者权益），两期对比（期末/年初）
// 数据与格式由同目录 balance.json 提供；运行时可用 --input data=xxx.json 覆盖

#import "/lib.typ": company-header, num, report-init

#show: report-init
#set page(paper: "a4", margin: (x: 14mm, y: 14mm))
#set text(size: 9pt)

// ===== 通用样式函数（income.typ 复用同一套） =====

// 金额：负数用括号、保留 d 位小数；none 输出空（占位行不留 0.00）
// report-init 已 set-group，num 自动带千分位；math:false 避免财务数字变数学字体
#let amt(n, d: 2) = if n == none { [] }
  else if n < 0 { [(#num(calc.abs(n), digits: d, math: false))] }
  else { [#num(n, digits: d, math: false)] }

// 中缝加粗竖线（左右两栏之间，位于第 4 列左边缘）
#let mid-stroke = 0.8pt + black

// 单元格：会计横线惯例——小计上单线、合计上粗下单；无竖线（中缝除外）
// kind: normal | group | subtotal | total
// mid: 是否为右栏首列（是则左边缘画中缝加粗线）
#let cell(v, kind: "normal", al: left, bold: false, mid: false) = {
  let st = if kind == "subtotal" { (top: 0.5pt, bottom: 0pt) }
    else if kind == "total" { (top: 0.75pt, bottom: 0.5pt) }
    else { (top: 0pt, bottom: 0pt) }
  let ls = if mid { mid-stroke } else { none }
  table.cell(
    align: al,
    stroke: (left: ls, right: none, top: st.top, bottom: st.bottom),
    text(weight: if bold { "bold" } else { "regular" })[#v],
  )
}

// 一栏三列（项目 + 两期金额）；k1/k2 为该栏两期金额的字段名（本模板 end/begin）
// mid 为真时首列（项目名）画中缝线
#let row3(r, k1, k2, mid: false) = {
  let k = r.at("type", default: "normal")
  let b = k == "subtotal" or k == "total"
  (
    cell(r.name, k, left, b, mid: mid),
    cell(amt(r.at(k1, default: none)), k, right, b),
    cell(amt(r.at(k2, default: none)), k, right, b),
  )
}

// 分组标题：整栏 3 列合并为 1 个 cell（只返回一个 cell，否则跨栏时列数错位）
#let group3(r, mid: false) = (
  table.cell(
    colspan: 3,
    fill: rgb(238, 238, 238),
    align: left,
    stroke: (left: if mid { mid-stroke } else { none }, right: none, top: 0.5pt, bottom: 0pt),
    text(weight: "bold")[#r.name],
  ),
)

// 空占位：一栏三列各一个空 cell（左右行数不等时补位，不可省略否则整行错位）
// mid 为真时首列画中缝线
#let blank3(mid: false) = (
  table.cell(fill: none, stroke: (left: if mid { mid-stroke } else { none }, right: none, top: none, bottom: none))[],
  table.cell(fill: none)[],
  table.cell(fill: none)[],
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

  // 左右按行号交错进同一张 6 列表格，行数不等的一侧用空 cell 补齐
  let n = calc.max(data.left.len(), data.right.len())
  let cells = ()
  for i in range(n) {
    let l = if i < data.left.len() { data.left.at(i) } else { none }
    let r = if i < data.right.len() { data.right.at(i) } else { none }
    cells += if l == none { blank3() }
      else if l.at("type", default: "") == "group" { group3(l) }
      else { row3(l, "end", "begin") }
    cells += if r == none { blank3(mid: true) }
      else if r.at("type", default: "") == "group" { group3(r, mid: true) }
      else { row3(r, "end", "begin", mid: true) }
  }

  // 两个总计放同一表格行：左三列=资产总计，右三列=负债权益总计，天然对齐
  cells += row3(data.left_total, "end", "begin")
  cells += row3(data.right_total, "end", "begin", mid: true)

  table(
    columns: (2fr, 1fr, 1fr, 2fr, 1fr, 1fr),
    stroke: none,
    table.header(
      table.cell(stroke: (bottom: 0.5pt))[项目],
      table.cell(stroke: (bottom: 0.5pt))[期末余额],
      table.cell(stroke: (bottom: 0.5pt))[年初余额],
      // 表头第 4 列（右栏项目名）画中缝线，与表体中缝贯通
      table.cell(stroke: (left: mid-stroke, right: none, bottom: 0.5pt))[项目],
      table.cell(stroke: (bottom: 0.5pt))[期末余额],
      table.cell(stroke: (bottom: 0.5pt))[年初余额],
    ),
    ..cells,
  )
}

// ===== 数据源 =====
#let data_source = sys.inputs.at("data", default: "balance.json")
#main(json(data_source))
