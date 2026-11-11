#import "/lib.typ": bussiness, company-header, hei, num, report-init, row-count, wrap

#show: report-init
#set page(width: 297mm, height: auto)
#set text(size: 10pt, font: bussiness)
#show heading: set text(font: bussiness)
#let number(n, d) = [#num(n, digits: d, math: false)]

// 美元汇率
#let rate(r1, r2) = {
  if r1 > r2 {
    text(fill: green)[#number(r1, 4)↑↑↑#number(r2, 4)]
  } else {
    text(fill: red)[#number(r1, 4)↓↓↓#number(r2, 4)]
  }
}
// 大于0绿色，小于0红色
#let fc(n) = {
  if n > 0 {
    green
  } else {
    red
  }
}

#let month-map = (
  Jan: "1月",
  Feb: "2月",
  Mar: "3月",
  Apr: "4月",
  May: "5月",
  Jun: "6月",
  Jul: "7月",
  Aug: "8月",
  Sep: "9月",
  Oct: "10月",
  Nov: "11月",
  Dec: "12月",
)

// 入口函数
#let main(data) = {
  // 日入库差异金额
  let day-product = (
    (
      data.product.normal.day.smt
        + data.product.rework_in.day.smt
        - data.product.rework_out.day.smt
        + data.product.normal.day.fpc
        + data.product.rework_in.day.fpc
        - data.product.rework_out.day.fpc
        + data.product.normal.day.comp
        + data.product.rework_in.day.comp
        - data.product.rework_out.day.comp
    )
      - data.forecast.product.day
  )
  let month-product = (
    data.product.normal.month.fpc
      + data.product.rework_in.month.fpc
      - data.product.rework_out.month.fpc
      + data.product.normal.month.smt
      + data.product.rework_in.month.smt
      - data.product.rework_out.month.smt
      + data.product.normal.month.comp
      + data.product.rework_in.month.comp
      - data.product.rework_out.month.comp
      - data.forecast.product.month
  )
  let day-sale = (
    (
      data.sale.normal.day.smt
        + data.sale.normal.day.fpc
        + data.sale.normal.day.comp
        - data.sale.return.day.smt
        - data.sale.return.day.fpc
        - data.sale.return.day.comp
        - data.sale.discount.day
    )
      - data.forecast.sale.day
  )
  let month-sale = (
    (
      data.sale.normal.month.smt
        + data.sale.normal.month.fpc
        + data.sale.normal.month.comp
        + data.sale.resell.month
        - data.sale.return.month.smt
        - data.sale.return.month.fpc
        - data.sale.return.month.comp
        - data.sale.discount.month
    )
      - data.forecast.sale.month
  )

  company-header()
  table(
    columns: (1.5fr, 1fr, 3fr),
    fill: rgb(219, 238, 244),
    //stroke: (top: none, left: none, right: none, bottom: 1pt + black),
    align: (x, y) => { if x == 0 { right } else if x == 1 { left } else { center } },
    [Date], [日期], [#data.date],
    [Remaining days], [剩余天数], [#data.remaining],
    table.cell(stroke: none, fill: none, colspan: 3)[],
    [Exchange], [美金利率], [#rate(data.curr_rate, data.previous_rate)],
    table.cell(stroke: none, fill: none, colspan: 3)[],

    // 成品入库
    table.cell(rowspan: 2, align: horizon)[Normal Production],
    table.cell(rowspan: 2, align: horizon)[正常生产入库],
    [#number(data.product.normal.day.smt + data.product.normal.day.fpc + data.product.normal.day.comp, 2)W],
    table.cell(
      align: left,
    )[FPC:#number(data.product.normal.day.fpc, 2)W SMT:#number(data.product.normal.day.smt, 2)W COMP:#number(data.product.normal.day.comp, 2)W],
    table.cell(stroke: none, fill: none, colspan: 3)[],

    // 累计成品入库
    table.cell(rowspan: 2, align: horizon)[Cumulative normal production],
    table.cell(rowspan: 2, align: horizon)[累计正常生产入库],
    [#number(data.product.normal.month.smt + data.product.normal.month.fpc + data.product.normal.month.comp, 2)W],
    table.cell(
      align: left,
    )[FPC:#number(data.product.normal.month.fpc, 2)W SMT:#number(data.product.normal.month.smt, 2)W COMP:#number(data.product.normal.month.comp, 2)W],
    table.cell(stroke: none, fill: none, colspan: 3)[],

    // 返工入库
    table.cell(rowspan: 2, align: horizon)[Rework product],
    table.cell(rowspan: 2, align: horizon)[返工生产入库],
    [#number(data.product.rework_in.day.smt + data.product.rework_in.day.fpc + data.product.rework_in.day.comp, 2)W],
    table.cell(
      align: left,
    )[FPC:#number(data.product.rework_in.day.fpc, 2)W SMT:#number(data.product.rework_in.day.smt, 2)W COMP:#number(data.product.rework_in.day.comp, 2)W],

    // 累计返工入库
    table.cell(rowspan: 2, align: horizon)[Cumulative rework product],
    table.cell(rowspan: 2, align: horizon)[累计返工生产入库],
    [#number(data.product.rework_in.month.smt + data.product.rework_in.month.fpc + data.product.rework_in.month.comp, 2)W],
    table.cell(
      align: left,
    )[FPC:#number(data.product.rework_in.month.fpc, 2)W SMT:#number(data.product.rework_in.month.smt, 2)W COMP:#number(data.product.rework_in.month.comp, 2)W],
    table.cell(stroke: none, fill: none, colspan: 3)[],

    // 返工领出
    table.cell(rowspan: 2, align: horizon)[Rework],
    table.cell(rowspan: 2, align: horizon)[退仓返工],
    text(
      fill: red,
    )[#number(-(data.product.rework_out.day.smt + data.product.rework_out.day.fpc + data.product.rework_out.day.comp), 2)W],
    table.cell(align: left, text(
      fill: red,
    )[FPC:#number(data.product.rework_out.day.fpc, 2)W SMT:#number(data.product.rework_out.day.smt, 2)W COMP:#number(data.product.rework_out.day.comp, 2)W]),

    // 累计返工领出
    table.cell(rowspan: 2, align: horizon)[Cumulative rework],
    table.cell(rowspan: 2, align: horizon)[累计退仓返工],
    text(
      fill: red,
    )[#number(-(data.product.rework_out.month.smt + data.product.rework_out.month.fpc + data.product.rework_out.month.comp), 2)W],
    table.cell(
      align: left,
      text(
        fill: red,
      )[FPC:#number(data.product.rework_out.month.fpc, 2)W SMT:#number(data.product.rework_out.month.smt, 2)W COMP:#number(data.product.rework_out.month.comp, 2)W],
    ),
    table.cell(stroke: none, fill: none, colspan: 3)[],

    // 日入库预测
    text(fill: blue)[*Forecast production(Day)*],
    text(fill: blue)[*计划生产入库（日）*],
    text(fill: blue)[*#number(data.forecast.product.day, 2)W*],
    table.cell(fill: rgb(255, 255, 0), text(fill: fc(day-product))[*Actual production(Day)*]),
    table.cell(fill: rgb(255, 255, 0), text(fill: fc(day-product))[*实际生产入库（日）*]),
    table.cell(
      fill: rgb(255, 255, 0),
      text(fill: fc(day-product))[*#number(day-product + data.forecast.product.day, 2)W ★★★★★* ],
    ),
    [*Discrepancy(Day)*],
    [*差异（日）*],
    [*#number(day-product, 2)W*],
    table.cell(stroke: none, fill: none, colspan: 3)[],

    // 累计入库
    table.cell(rowspan: 2, fill: rgb(255, 255, 0), align: horizon, text(
      fill: fc(month-product),
    )[*Cumulative production*]),
    table.cell(rowspan: 2, fill: rgb(255, 255, 0), align: horizon, text(
      fill: fc(month-product),
    )[*累计生产入库*]),
    table.cell(
      fill: rgb(255, 255, 0),
      text(fill: fc(month-product))[*#number(month-product + data.forecast.product.month, 2)W ★★★★★*],
    ),
    table.cell(
      align: left,
      fill: rgb(255, 255, 0),
      text(
        fill: fc(month-product),
      )[*FPC:#number(data.product.normal.month.fpc + data.product.rework_in.month.fpc - data.product.rework_out.month.fpc, 2)W SMT:#number(data.product.normal.month.smt + data.product.rework_in.month.smt - data.product.rework_out.month.smt, 2)W COMP:#number(data.product.normal.month.comp + data.product.rework_in.month.comp - data.product.rework_out.month.comp, 2)W*],
    ),
    table.cell(stroke: none, fill: none, colspan: 3)[],

    // 累计入库预测
    table.cell(
      rowspan: 2,
      fill: rgb(255, 255, 0),
      text(fill: blue)[*Forecast production(Month)*],
    ),
    table.cell(
      rowspan: 2,
      fill: rgb(255, 255, 0),
      text(fill: blue)[*计划生产入库（月）*],
    ),
    table.cell(
      rowspan: 2,
      fill: rgb(255, 255, 0),
      text(fill: blue)[*#number(data.forecast.product.month, 2)W*],
    ),
    table.cell(
      rowspan: 2,
      fill: rgb(255, 255, 0),
      text(fill: fc(month-product))[*Discrepancy(Month)*],
    ),
    table.cell(
      rowspan: 2,
      fill: rgb(255, 255, 0),
      text(fill: fc(month-product))[*差异（月）*],
    ),
    table.cell(
      rowspan: 2,
      fill: rgb(255, 255, 0),
      text(fill: fc(month-product))[*#number(month-product, 2)W*],
    ),
    table.cell(stroke: none, fill: none, colspan: 3)[],

    // 成品出库
    table.cell(rowspan: 2, align: horizon)[Sales],
    table.cell(rowspan: 2, align: horizon)[销售],
    [#number(data.sale.normal.day.smt + data.sale.normal.day.fpc + data.sale.normal.day.comp, 2)W],
    table.cell(
      align: left,
    )[FPC:#number(data.sale.normal.day.fpc, 2)W SMT:#number(data.sale.normal.day.smt, 2)W COMP:#number(data.sale.normal.day.comp, 2)W],
    table.cell(stroke: none, fill: none, colspan: 3)[],

    // 销退
    table.cell(rowspan: 2, align: horizon)[Returns],
    table.cell(rowspan: 2, align: horizon)[客退],
    text(
      fill: red,
    )[#number(-(data.sale.return.day.smt + data.sale.return.day.fpc + data.sale.return.day.comp), 2)W],
    table.cell(
      align: left,
      text(
        fill: red,
      )[FPC:#number(-data.sale.return.day.fpc, 2)W SMT:#number(-data.sale.return.day.smt, 2)W COMP:#number(-data.sale.return.day.comp, 2)W],
    ),
    table.cell(stroke: none, fill: none, colspan: 3)[],

    // 累计销退
    table.cell(rowspan: 2, align: horizon)[Cumulative returns],
    table.cell(rowspan: 2, align: horizon)[累计客退],
    text(
      fill: red,
    )[#number(-(data.sale.return.month.smt + data.sale.return.month.fpc + data.sale.return.month.comp), 2)W],
    table.cell(
      align: left,
      text(
        fill: red,
      )[FPC:#number(-data.sale.return.month.fpc, 2)W SMT:#number(-data.sale.return.month.smt, 2)W COMP:#number(-data.sale.return.month.comp, 2)W],
    ),
    table.cell(stroke: none, fill: none, colspan: 3)[],

    // 折让
    [Discount],
    [折让],
    [#number(-data.sale.discount.day, 2)W],
    [Cumulative discount],
    [累计折让],
    [#number(-data.sale.discount.month, 2)W],
    table.cell(stroke: none, fill: none, colspan: 3)[],

    // 日销售预测
    text(fill: blue)[*Forecast revenues(Day)*],
    text(fill: blue)[*计划销售（日）*],
    text(fill: blue)[*#number(data.forecast.sale.day, 2)W*],
    table.cell(
      fill: rgb(255, 255, 0),
      text(fill: fc(day-sale))[*Actual revenues(Day)*],
    ),
    table.cell(
      fill: rgb(255, 255, 0),
      text(fill: fc(day-sale))[*实际销售（日）*],
    ),
    table.cell(
      fill: rgb(255, 255, 0),
      text(fill: fc(day-sale))[*#number(day-sale + data.forecast.sale.day, 2)W ★★★★★*],
    ),
    [*Discrepancy(Day)*],
    [*差异（日）*],
    [*#number(day-sale, 2)W*],
    table.cell(stroke: none, fill: none, colspan: 3)[],

    // 累计出货
    table.cell(rowspan: 2, align: horizon)[Cumulative sales],
    table.cell(rowspan: 2, align: horizon)[累计销售],
    [#number((
        data.sale.normal.month.smt + data.sale.normal.month.fpc + data.sale.normal.month.comp - data.sale.return.month.smt - data.sale.return.month.fpc - data.sale.return.month.comp - data.sale.discount.month
      ), 2)W],
    table.cell(
      align: left,
    )[FPC:#number(data.sale.normal.month.fpc - data.sale.return.month.fpc, 2)W SMT:#number(data.sale.normal.month.smt - data.sale.return.month.smt, 2)W COMP:#number(data.sale.normal.month.comp - data.sale.return.month.comp, 2)W DCT:#number(-data.sale.discount.month, 2)W],
    table.cell(stroke: none, fill: none, colspan: 3)[],

    // 材料转卖
    [Material resell],
    [材料转售],
    [#number(data.sale.resell.day, 2)W],
    [Cumulative material resell],
    [累计材料转售],
    [#number(data.sale.resell.month, 2)W],
    table.cell(stroke: none, fill: none, colspan: 3)[],

    // 未签收
    table.cell(rowspan: 3, align: horizon)[Unreceipted(#data.last_month)],
    table.cell(rowspan: 3, align: horizon)[销售未签收（#month-map.at(data.last_month)）],
    [#number(data.sale.unsign.fpc + data.sale.unsign.smt + data.sale.unsign.comp, 2)W],
    table.cell(
      align: left,
    )[FPC:#number(data.sale.unsign.fpc, 2)W SMT:#number(data.sale.unsign.smt, 2)W COMP:#number(data.sale.unsign.comp, 2)W],
    table.cell(align: left)[Sample:#number(data.sale.unsign.sample, 2)W],
    table.cell(stroke: none, fill: none, colspan: 3)[],

    // 应收
    table.cell(rowspan: 2, fill: rgb(255, 255, 0), align: horizon, text(fill: red)[*Accounts due*]),
    table.cell(rowspan: 2, fill: rgb(255, 255, 0), align: horizon, text(fill: red)[*实际应收*]),
    table.cell(
      fill: rgb(255, 255, 0),
      text(fill: red)[*#number((
        (data.sale.normal.month.smt + data.sale.normal.month.fpc + data.sale.normal.month.comp - data.sale.return.month.smt - data.sale.return.month.fpc - data.sale.return.month.comp - data.sale.discount.month) + (data.sale.resell.month) + (data.sale.unsign.fpc + data.sale.unsign.smt + data.sale.unsign.comp)
      ), 2)W ★★★★★*],
    ),
    table.cell(align: left, fill: rgb(255, 255, 0), text(
      fill: red,
    )[*FPC:#number(data.sale.normal.month.fpc + data.sale.unsign.fpc - data.sale.return.month.fpc, 2)W SMT:#number(data.sale.normal.month.smt + data.sale.unsign.smt - data.sale.return.month.smt, 2)W COMP:#number(data.sale.normal.month.comp + data.sale.unsign.comp - data.sale.return.month.comp, 2)W\
    Other:#number(data.sale.resell.month, 2)W DCT: #number(-data.sale.discount.month, 2)W*]),
    table.cell(stroke: none, fill: none, colspan: 3)[],

    // 累计预测
    table.cell(
      fill: rgb(255, 255, 0),
      text(fill: blue)[*Forecast revenues(Month)*],
    ),
    table.cell(
      fill: rgb(255, 255, 0),
      text(fill: blue)[*计划销售（月）*],
    ),
    table.cell(
      fill: rgb(255, 255, 0),
      text(fill: blue)[*#number(data.forecast.sale.month, 2)W*],
    ),
    table.cell(
      fill: rgb(255, 255, 0),
      text(fill: fc(month-sale))[*Discrepancy(Month)*],
    ),
    table.cell(
      fill: rgb(255, 255, 0),
      text(fill: fc(month-sale))[*差异（月）*],
    ),
    table.cell(
      fill: rgb(255, 255, 0),
      text(fill: fc(month-sale))[*#number(month-sale, 2)W*],
    ),
    table.cell(stroke: none, fill: none, colspan: 3)[],

    // 库存
    [Normal Stock articles],
    [正常成品库存],
    text(fill: red)[*#number(data.stock.normal, 2)W ★★★★★*],
    [Sample Stock articles],
    [样品库存],
    [#number(data.stock.sample, 2)W],
    [Inaction stock articles],
    [呆滞库存],
    [#number(data.stock.inaction, 2)W],
    [Customer Return Stock articles],
    [客退库存],
    [#number(data.stock.return, 2)W],
  )
}


#let data_source = sys.inputs.at("data", default: "data.T7sE.json")  // 数据来源
#let data = json(data_source)
#main(data)
