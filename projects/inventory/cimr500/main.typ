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
    columns: (1fr, 2fr),
    fill: rgb(219, 238, 244),
    //stroke: (top: none, left: none, right: none, bottom: 1pt + black),
    align: (x, y) => { if x == 0 { right } else { center } },
    [Date], [#data.date],
    [Remaining days], [#data.remaining],
    table.cell(stroke: none, fill: none, colspan: 2)[],
    [Exchange], [#rate(data.curr_rate, data.previous_rate)],
    table.cell(stroke: none, fill: none, colspan: 2)[],

    // 成品入库
    table.cell(rowspan: 2, align: horizon)[Normal Production],
    [#number(data.product.normal.day.smt + data.product.normal.day.fpc + data.product.normal.day.comp, 2)W],
    table.cell(
      align: left,
    )[FPC:#number(data.product.normal.day.fpc, 2)W SMT:#number(data.product.normal.day.smt, 2)W COMP:#number(data.product.normal.day.comp, 2)W],
    table.cell(stroke: none, fill: none, colspan: 2)[],

    // 累计成品入库
    table.cell(rowspan: 2, align: horizon)[Cumulative normal production],
    [#number(data.product.normal.month.smt + data.product.normal.month.fpc + data.product.normal.month.comp, 2)W],
    table.cell(
      align: left,
    )[FPC:#number(data.product.normal.month.fpc, 2)W SMT:#number(data.product.normal.month.smt, 2)W COMP:#number(data.product.normal.month.comp, 2)W],
    table.cell(stroke: none, fill: none, colspan: 2)[],

    // 返工入库
    table.cell(rowspan: 2, align: horizon)[Rework product],
    [#number(data.product.rework_in.day.smt + data.product.rework_in.day.fpc + data.product.rework_in.day.comp, 2)W],
    table.cell(
      align: left,
    )[FPC:#number(data.product.rework_in.day.fpc, 2)W SMT:#number(data.product.rework_in.day.smt, 2)W COMP:#number(data.product.rework_in.day.comp, 2)W],

    // 累计返工入库
    table.cell(rowspan: 2, align: horizon)[Cumulative rework product],
    [#number(data.product.rework_in.month.smt + data.product.rework_in.month.fpc + data.product.rework_in.month.comp, 2)W],
    table.cell(
      align: left,
    )[FPC:#number(data.product.rework_in.month.fpc, 2)W SMT:#number(data.product.rework_in.month.smt, 2)W COMP:#number(data.product.rework_in.month.comp, 2)W],
    table.cell(stroke: none, fill: none, colspan: 2)[],

    // 返工领出
    table.cell(rowspan: 2, align: horizon)[Rework],
    text(
      fill: red,
    )[#number(data.product.rework_out.day.smt + data.product.rework_out.day.fpc + data.product.rework_out.day.comp, 2)W],
    table.cell(align: left, text(
      fill: red,
    )[FPC:#number(data.product.rework_out.day.fpc, 2)W SMT:#number(data.product.rework_out.day.smt, 2)W COMP:#number(data.product.rework_out.day.comp, 2)W]),

    // 累计返工领出
    table.cell(rowspan: 2, align: horizon)[Cumulative rework],
    text(
      fill: red,
    )[#number(data.product.rework_out.month.smt + data.product.rework_out.month.fpc + data.product.rework_out.month.comp, 2)W],
    table.cell(
      align: left,
      text(
        fill: red,
      )[FPC:#number(data.product.rework_out.month.fpc, 2)W SMT:#number(data.product.rework_out.month.smt, 2)W COMP:#number(data.product.rework_out.month.comp, 2)W],
    ),
    table.cell(stroke: none, fill: none, colspan: 2)[],

    // 日入库预测
    text(fill: blue)[*Forecast production(Day)*],
    text(fill: blue)[*#number(data.forecast.product.day, 2)W*],
    table.cell(fill: rgb(255, 255, 0), text(fill: fc(day-product))[*Actual production(Day)*]),
    table.cell(
      fill: rgb(255, 255, 0),
      text(fill: fc(day-product))[*#number(day-product + data.forecast.product.day, 2)W ★★★★★* ],
    ),
    [*Discrepancy(Day)*],
    [*#number(day-product, 2)W*],
    table.cell(stroke: none, fill: none, colspan: 2)[],

    // 累计入库
    table.cell(rowspan: 2, fill: rgb(255, 255, 0), align: horizon, text(
      fill: fc(month-product),
    )[*Cumulative production*]),
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
    table.cell(stroke: none, fill: none, colspan: 2)[],

    // 累计入库预测
    table.cell(
      rowspan: 2,
      fill: rgb(255, 255, 0),
      text(fill: blue)[*Forecast production(Month)*],
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
      text(fill: fc(month-product))[*#number(month-product, 2)W*],
    ),
    table.cell(stroke: none, fill: none, colspan: 2)[],

    // 成品出库
    table.cell(rowspan: 2, align: horizon)[Sales],
    [#number(data.sale.normal.day.smt + data.sale.normal.day.fpc + data.sale.normal.day.comp, 2)W],
    table.cell(
      align: left,
    )[FPC:#number(data.sale.normal.day.fpc, 2)W SMT:#number(data.sale.normal.day.smt, 2)W COMP:#number(data.sale.normal.day.comp, 2)W],
    table.cell(stroke: none, fill: none, colspan: 2)[],

    // 销退
    table.cell(rowspan: 2, align: horizon)[Returns],
    text(
      fill: red,
    )[#number(-(data.sale.return.day.smt + data.sale.return.day.fpc + data.sale.return.day.comp), 2)W],
    table.cell(
      align: left,
      text(
        fill: red,
      )[FPC:#number(-data.sale.return.day.fpc, 2)W SMT:#number(-data.sale.return.day.smt, 2)W COMP:#number(-data.sale.return.day.comp, 2)W],
    ),
    table.cell(stroke: none, fill: none, colspan: 2)[],

    // 累计销退
    table.cell(rowspan: 2, align: horizon)[Cumulative returns],
    text(
      fill: red,
    )[#number(-(data.sale.return.month.smt + data.sale.return.month.fpc + data.sale.return.month.comp), 2)W],
    table.cell(
      align: left,
      text(
        fill: red,
      )[FPC:#number(-data.sale.return.month.fpc, 2)W SMT:#number(-data.sale.return.month.smt, 2)W COMP:#number(-data.sale.return.month.comp, 2)W],
    ),
    table.cell(stroke: none, fill: none, colspan: 2)[],

    // 折让
    [Discount],
    [#number(-data.sale.discount.day, 2)W],
    [Cumulative discount],
    [#number(-data.sale.discount.month, 2)W],
    table.cell(stroke: none, fill: none, colspan: 2)[],

    // 日销售预测
    text(fill: blue)[*Forecast revenues(Day)*],
    text(fill: blue)[*#number(data.forecast.sale.day, 2)W*],
    table.cell(
      fill: rgb(255, 255, 0),
      text(fill: fc(day-sale))[*Actual revenues(Day)*],
    ),
    table.cell(
      fill: rgb(255, 255, 0),
      text(fill: fc(day-sale))[*#number(day-sale + data.forecast.sale.day, 2)W ★★★★★*],
    ),
    [*Discrepancy(Day)*],
    [*#number(day-sale, 2)W*],
    table.cell(stroke: none, fill: none, colspan: 2)[],

    // 累计出货
    table.cell(rowspan: 2, align: horizon)[Cumulative sales],
    [#number(month-sale + data.forecast.sale.month, 2)W],
    table.cell(
      align: left,
    )[FPC:#number(data.sale.normal.month.fpc - data.sale.return.month.fpc, 2)W SMT:#number(data.sale.normal.month.smt - data.sale.return.month.smt, 2)W COMP:#number(data.sale.normal.month.comp - data.sale.return.month.comp, 2)W DCT:#number(-data.sale.discount.month, 2)W],
    table.cell(stroke: none, fill: none, colspan: 2)[],

    // 材料转卖
    [Material resell],
    [#number(data.sale.resell.day, 2)W],
    [Cumulative material resell],
    [#number(data.sale.resell.month, 2)W],
    table.cell(stroke: none, fill: none, colspan: 2)[],

    // 未签收
    table.cell(rowspan: 3, align: horizon)[Unreceipted(#data.last_month)],
    [#number(data.sale.unsign.fpc + data.sale.unsign.smt + data.sale.unsign.comp, 2)W],
    table.cell(
      align: left,
    )[FPC:#number(data.sale.unsign.fpc, 2)W SMT:#number(data.sale.unsign.smt, 2)W COMP:#number(data.sale.unsign.comp, 2)W],
    table.cell(align: left)[Sample:#number(data.sale.unsign.sample, 2)W],
    table.cell(stroke: none, fill: none, colspan: 2)[],

    // 应收
    table.cell(rowspan: 2, fill: rgb(255, 255, 0), align: horizon, text(fill: red)[*Accounts due*]),
    table.cell(
      fill: rgb(255, 255, 0),
      text(fill: red)[*#number((
        month-sale + data.forecast.sale.month + data.sale.resell.month + data.sale.unsign.fpc + data.sale.unsign.smt + data.sale.unsign.comp
      ), 2)W ★★★★★*],
    ),
    table.cell(align: left, fill: rgb(255, 255, 0), text(
      fill: red,
    )[*FPC:#number(data.sale.normal.month.fpc + data.sale.unsign.fpc - data.sale.return.month.fpc, 2)W SMT:#number(data.sale.normal.month.smt + data.sale.unsign.smt - data.sale.return.month.smt, 2)W COMP:#number(data.sale.normal.month.comp + data.sale.unsign.comp - data.sale.return.month.comp, 2)W Other:#number(data.sale.resell.month, 2)W DCT: #number(-data.sale.discount.month, 2)W*]),
    table.cell(stroke: none, fill: none, colspan: 2)[],

    // 累计预测
    table.cell(
      fill: rgb(255, 255, 0),
      text(fill: blue)[*Forecast revenues(Month)*],
    ),
    table.cell(
      fill: rgb(255, 255, 0),
      text(fill: blue)[*#number(month-sale + data.forecast.sale.month, 2)W*],
    ),
    table.cell(
      fill: rgb(255, 255, 0),
      text(fill: fc(month-sale))[*Discrepancy(Month)*],
    ),
    table.cell(
      fill: rgb(255, 255, 0),
      text(fill: fc(month-sale))[*#number(month-sale, 2)W*],
    ),
    table.cell(stroke: none, fill: none, colspan: 2)[],

    // 库存
    [Normal Stock articles],
    text(fill: red)[*#number(data.stock.normal, 2)W ★★★★★*],
    [Sample Stock articles],
    [#number(data.stock.sample, 2)W],
    [Inaction stock articles],
    [#number(data.stock.inaction, 2)W],
    [Customer Return Stock articles],
    [#number(data.stock.return, 2)W],
  )
}


#let data_source = sys.inputs.at("data", default: "cimr500.all.json")  // 数据来源
#let data = json(data_source)
#main(data)
