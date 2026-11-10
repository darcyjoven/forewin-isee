#import "/lib.typ": bussiness, company-header, decimal, format-table, hei, num, report-init, row-count, wrap


// 本月总天数
#let days-in-month(date) = {
  let next-month = if date.month() == 12 {
    datetime(year: date.year() + 1, month: 1, day: 1)
  } else {
    datetime(year: date.year(), month: date.month() + 1, day: 1)
  }

  int(
    (
      next-month
        - datetime(
          year: date.year(),
          month: date.month(),
          day: 1,
        )
    ).days(),
  )
}
// 转为日期
#let parse-date(value) = {
  let parts = value.split("-")

  datetime(
    year: int(parts.at(0)),
    month: int(parts.at(1)),
    day: int(parts.at(2)),
  )
}
// header
#let header(days, today) = (
  [#today.month()月#today.day()日],
  [累计金额（万元）],
  ..for i in range(days) {
    (align(center)[#today.month()- #{ i + 1 }],)
  },
)

#let detail(data, days) = for i in range(data.len()) {
  let format(number) = number
  if i == 13 {
    format = number => decimal(number, digits: 0)
  }
  if i == 14 {
    format = number => decimal(number, digits: 4, group: (separator: ""))
  }

  let row = (
    [#data.at(i).col05],
    [#format(data.at(i).col06)],
    [#format(data.at(i).col07)],
    [#format(data.at(i).col08)],
    [#format(data.at(i).col09)],
    [#format(data.at(i).col10)],
    [#format(data.at(i).col11)],
    [#format(data.at(i).col12)],
    [#format(data.at(i).col13)],
    [#format(data.at(i).col14)],
    [#format(data.at(i).col15)],
    [#format(data.at(i).col16)],
    [#format(data.at(i).col17)],
    [#format(data.at(i).col18)],
    [#format(data.at(i).col19)],
    [#format(data.at(i).col20)],
    [#format(data.at(i).col21)],
    [#format(data.at(i).col22)],
    [#format(data.at(i).col23)],
    [#format(data.at(i).col24)],
    [#format(data.at(i).col25)],
    [#format(data.at(i).col26)],
    [#format(data.at(i).col27)],
    [#format(data.at(i).col28)],
    [#format(data.at(i).col29)],
    [#format(data.at(i).col30)],
    [#format(data.at(i).col31)],
    [#format(data.at(i).col32)],
    [#format(data.at(i).col33)],
    [#format(data.at(i).col34)],
    [#format(data.at(i).col35)],
    [#format(data.at(i).col36)],
    [#format(data.at(i).col37)],
  )
  row.slice(0, days + 2)
}


#let main(data) = {
  show: report-init
  set page(width: 297mm, height: auto)
  set text(size: 10pt, font: bussiness)
  show heading: set text(font: bussiness)
  let number(n, d) = [#num(n, digits: d, math: false)]

  // 美元汇率
  let rate(r1, r2) = {
    if r1 > r2 {
      text(fill: green)[#number(r1, 4)↑↑↑#number(r2, 4)]
    } else {
      text(fill: red)[#number(r1, 4)↓↓↓#number(r2, 4)]
    }
  }
  // 大于0绿色，小于0红色
  let fc(n) = {
    if n > 0 {
      green
    } else {
      red
    }
  }

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

  // company-header()
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
      text(fill: blue)[*#number(data.forecast.sale.month, 2)W*],
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


#let avg_table(data, days, today) = {
  show: report-init
  set text(font: bussiness)
  set page(width: 100cm, height: auto, margin: 1.5cm)
  show table: format-table(none, ..((digits: 2),) * (days + 1))

  table(
    columns: (5cm, 4cm, ..range(days).map(_ => 1fr)),
    fill: (_, x) => {
      if x == 0 {
        rgb(252, 213, 181)
      } else if x == 1 {
        rgb(219, 238, 244)
      } else if x == 2 {
        rgb(215, 228, 189)
      } else if x == 3 {
        rgb(255, 255, 0)
      } else if x == 4 {
        rgb(219, 238, 244)
      } else if x == 5 {
        rgb(215, 228, 189)
      } else if x == 6 {
        rgb(255, 255, 0)
      } else if x == 7 {
        rgb(255, 255, 255)
      } else if x == 8 {
        rgb(215, 228, 189)
      } else if x == 9 {
        rgb(255, 255, 0)
      } else if x == 10 {
        rgb(255, 255, 255)
      } else if x == 11 {
        rgb(255, 255, 0)
      } else if x == 12 {
        rgb(219, 238, 244)
      } else if x == 13 {
        rgb(255, 255, 255)
      } else if x == 14 {
        rgb(219, 238, 244)
      } else if x == 15 {
        rgb(255, 255, 255)
      }
    },
    table.header(..header(days, today)),
    ..detail(data, days),
  )
}

#let data_source = sys.inputs.at("data", default: "/json/cimr500.all.json")  // 数据来源
#let data = json(data_source)
#main(data)

#let today = sys.inputs.at("date", default: "2026-08-27")  // 日期
#let avg_data_source = sys.inputs.at("avg", default: "cimr500.avg.json")  // 数据来源
#let avg_data = json(avg_data_source)
#let today = parse-date(today)
#let days = days-in-month(today)
#avg_table(avg_data, days, today)
