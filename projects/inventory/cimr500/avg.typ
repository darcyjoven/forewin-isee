#import "/lib.typ": bussiness, decimal, format-table, num, report-init

#show: report-init
#set text(font: bussiness)
#set page(width: 100cm, height: auto, margin: 1.5cm)

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

// columns
#let columns(days) = (
  5cm,
  4cm,
  ..range(days).map(_ => 1fr),
)

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

#let avg_table(data, days, today) = {
  show table: format-table(none, ..((digits: 2),) * (days + 1))
  table(
    columns: columns(days),
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

#let today = sys.inputs.at("date", default: "2026-08-27")  // 日期
#let avg_data_source = sys.inputs.at("avg", default: "avg.json")  // 数据来源

#let avg_data = json(avg_data_source)
#let today = parse-date(today)
#let days = days-in-month(today)

#avg_table(avg_data, days, today)

