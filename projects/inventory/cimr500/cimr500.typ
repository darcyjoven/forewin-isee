#import "/lib.typ": bussiness, company-header, hei, num, set-group, song

#let int(i) = num(i, digits: 2, math: false)
#set text(font: bussiness)
#show heading: set text(font: hei)
#set page(paper: "a4", margin: (
  top: 20mm,
  bottom: 18mm,
  left: 18mm,
  right: 18mm,
))
#set-group(
  separator: ",",
  threshold: 4,
)

// 达成
#let achieve(content) = table.cell(stroke: (top: 1pt + black), fill: rgb(238, 246, 238), text(
  fill: rgb(53, 107, 53),
  weight: "bold",
)[#content])
// // 未达成
#let unachieve(content) = table.cell(stroke: (top: 1pt + black), fill: rgb(251, 239, 239), text(
  fill: rgb(143, 48, 48),
  weight: "bold",
)[#content])

// 正文
#let normal(content) = table.cell(align: right, text(fill: rgb(34, 34, 34))[#content])
// 合计
#let head(content) = table.cell(stroke: (top: 1pt + black), fill: rgb(214, 214, 214), text(
  fill: rgb(17, 17, 17),
  weight: "bold",
)[#content])
// 小计
#let subtotal(content) = table.cell(stroke: (top: 1pt + black), text(fill: rgb(34, 34, 34), weight: "bold")[#content])

// 明细表
#let detail(data) = {
  set text(fill: rgb(34, 34, 34), font: bussiness, size: 9pt)

  // 成品入库
  let ind = data.product.normal.day.fpc + data.product.normal.day.smt + data.product.normal.day.comp
  let inm = data.product.normal.month.fpc + data.product.normal.month.smt + data.product.normal.month.comp
  // 返工入库
  let irid = data.product.rework_in.day.fpc + data.product.rework_in.day.smt + data.product.rework_in.day.comp
  let irim = data.product.rework_in.month.fpc + data.product.rework_in.month.smt + data.product.rework_in.month.comp
  // 返工领出
  let irod = -(data.product.rework_out.day.fpc + data.product.rework_out.day.smt + data.product.rework_out.day.comp)
  let irom = -(
    data.product.rework_out.month.fpc + data.product.rework_out.month.smt + data.product.rework_out.month.comp
  )
  // 差异金额

  let idiffd = ind + irid + irod - data.forecast.product.day
  let idiffm = inm + irim + irom - data.forecast.product.month

  let stock = data.stock.normal + data.stock.sample + data.stock.inaction + data.stock.return

  // 成品出货
  let ond = data.sale.normal.day.fpc + data.sale.normal.day.smt + data.sale.normal.day.comp
  let onm = data.sale.normal.month.fpc + data.sale.normal.month.smt + data.sale.normal.month.comp
  // 销退
  let ord = -(data.sale.return.day.fpc + data.sale.return.day.smt + data.sale.return.day.comp)
  let orm = -(data.sale.return.month.fpc + data.sale.return.month.smt + data.sale.return.month.comp)
  // 出货小计
  let osubtd = (
    data.sale.normal.day.fpc + data.sale.normal.day.smt + data.sale.normal.day.comp + ord - data.sale.discount.day
  )
  // 出货总计
  let otdf = data.sale.normal.month.fpc - data.sale.return.month.fpc
  let otds = data.sale.normal.month.smt - data.sale.return.month.smt
  let otdc = data.sale.normal.month.comp - data.sale.return.month.comp
  let otdd = -data.sale.discount.month
  // 未签收
  let unsign = data.sale.unsign.smt + data.sale.unsign.fpc + data.sale.unsign.comp
  // 收入总计
  let dtdf = data.sale.normal.month.fpc - data.sale.return.month.fpc + data.sale.unsign.fpc
  let dtds = data.sale.normal.month.smt - data.sale.return.month.smt + data.sale.unsign.smt
  let dtdc = data.sale.normal.month.comp - data.sale.return.month.comp + data.sale.unsign.comp
  let dtdo = data.sale.resell.month
  let dtdd = -data.sale.discount.month
  // 差异金额
  let odiifd = osubtd - data.forecast.sale.day
  let odiffm = dtdf + dtds + dtdc + dtdo + dtdd - data.forecast.sale.month

  // 入库部分
  let product = (
    (table.cell(colspan: 2, fill: none, head("入库"))),
    (normal("光板"), int(data.product.normal.day.fpc)),
    (normal("组装"), int(data.product.normal.day.smt)),
    (normal("器件"), int(data.product.normal.day.comp)),
    (subtotal("成品入库小计"), subtotal(int(ind))),
    (normal("光板"), int(data.product.rework_in.day.fpc)),
    (normal("组装"), int(data.product.rework_in.day.smt)),
    (normal("器件"), int(data.product.rework_in.day.comp)),
    (subtotal("返工入库小计"), subtotal(int(irid))),
    (normal("光板"), int(-data.product.rework_out.day.fpc)),
    (normal("组装"), int(-data.product.rework_out.day.smt)),
    (normal("器件"), int(-data.product.rework_out.day.comp)),
    (subtotal("返工领出小计"), subtotal(int(irod))),
    (head("入库小计"), head(int(ind + irid + irod))),
    (head("入库计划"), head(int(data.forecast.product.day))),
    if (idiffd < 0) {
      (unachieve("缺口"), unachieve(int(idiffd)))
    } else {
      (achieve("超额"), achieve(int(idiffd)))
    },
    (table.cell(colspan: 2, fill: none, head("（库存）"))),
    (normal("（成品）"), [(#int(data.stock.normal))]),
    (normal("（样品）"), [(#int(data.stock.sample))]),
    (normal("（呆滞）"), [(#int(data.stock.inaction))]),
    (normal("（客退）"), [(#int(data.stock.return))]),
    (head("（库存合计）"), head([(#int(stock))])),
    // (table.cell(colspan: 2, fill: none, head(""))),
    (normal("光板"), int(data.product.normal.month.fpc)),
    (normal("组装"), int(data.product.normal.month.smt)),
    (normal("器件"), int(data.product.normal.month.comp)),
    (subtotal("本月成品入库合计"), subtotal(int(inm))),
    (normal("光板"), int(data.product.rework_in.month.fpc)),
    (normal("组装"), int(data.product.rework_in.month.smt)),
    (normal("器件"), int(data.product.rework_in.month.comp)),
    (subtotal("本月返工入库合计"), subtotal(int(irim))),
    (normal("光板"), int(-data.product.rework_out.month.fpc)),
    (normal("组装"), int(-data.product.rework_out.month.smt)),
    (normal("器件"), int(-data.product.rework_out.month.comp)),
    (subtotal("本月返工领出合计"), subtotal(int(irom))),
    (head("本月入库合计"), head(int(inm + irim + irom))),
    (head("本月入库计划"), head(int(data.forecast.product.month))),
    // (head("超额/缺口"), head(int(idiffm))),
    if (idiffm < 0) {
      (unachieve("缺口"), unachieve(int(idiffm)))
    } else {
      (achieve("超额"), achieve(int(idiffm)))
    },
  )
  // 出库部分
  let sale = (
    (table.cell(colspan: 2, fill: none, head("出库"))),
    (normal("光板"), int(data.sale.normal.day.fpc)),
    (normal("组装"), int(data.sale.normal.day.smt)),
    (normal("器件"), int(data.sale.normal.day.comp)),
    (subtotal("成品出货小计"), subtotal(int(ond))),
    (normal("光板"), int(-data.sale.return.day.fpc)),
    (normal("组装"), int(-data.sale.return.day.smt)),
    (normal("器件"), int(-data.sale.return.day.comp)),
    (subtotal("成品销退小计"), subtotal(int(ord))),
    (subtotal("折扣小计"), subtotal(int(-data.sale.discount.day))),
    (head("出货小计"), head(int(osubtd))),
    (head("出货计划"), head(int(data.forecast.sale.day))),
    // (subtotal("超额/缺口"), subtotal(int(odiifd))),
    if (odiifd < 0) {
      (unachieve("缺口"), unachieve(int(odiifd)))
    } else {
      (achieve("超额"), achieve(int(odiifd)))
    },
    (normal("光板"), int(-data.sale.return.month.fpc)),
    (normal("组装"), int(-data.sale.return.month.smt)),
    (normal("器件"), int(-data.sale.return.month.comp)),
    (subtotal("本月成品销退总计"), subtotal(int(orm))),
    (normal("光板"), int(otdf)),
    (normal("组装"), int(otds)),
    (normal("器件"), int(otdc)),
    (normal("折扣"), int(otdd)),
    (subtotal("本月出货总计"), subtotal(int(otdf + otds + otdc + otdd))),
    (subtotal("材料转卖小计"), subtotal(int(data.sale.resell.day))),
    (subtotal("本月材料转卖总计"), subtotal(int(data.sale.resell.month))),
    (normal("光板"), int(data.sale.unsign.fpc)),
    (normal("组装"), int(data.sale.unsign.smt)),
    (normal("器件"), int(data.sale.unsign.fpc)),
    (subtotal("上月未签收总计"), subtotal(int(unsign))),
    (subtotal("（样品未签收）"), subtotal([(#int(data.sale.unsign.sample))])),
    (normal("光板"), int(dtdf)),
    (normal("器件"), int(dtds)),
    (normal("组装"), int(dtdc)),
    (normal("  "), int(dtdo)),
    (normal("折扣"), int(dtdd)),
    (head("本月收入合计"), head(int(odiffm + data.forecast.sale.month))),
    (head("本月收入计划"), head(int(data.forecast.sale.month))),
    // (head("超额/缺口"), head(int(odiffm))),
    if (odiffm < 0) {
      (unachieve("缺口"), unachieve(int(odiffm)))
    } else {
      (achieve("超额"), achieve(int(odiffm)))
    },
  )
  let result = ()

  for i in range(product.len()) {
    result.push(product.at(i))
    result.push(sale.at(i))
  }
  let result = result.flatten()

  table(
    columns: (1fr, 1fr, 1fr, 1fr),
    fill: rgb(243, 243, 243),
    stroke: (x, y) => {
      if x == 1 {
        (
          right: 1pt + black,
          top: 0.5pt + black,
          bottom: 0.5pt + black,
          left: 0.5pt + black,
        )
      } else if x == 2 {
        (
          left: 1pt + black,
          top: 0.5pt + black,
          right: 0.5pt + black,
          bottom: 0.5pt + black,
        )
      } else {
        0.5pt + black
      }
    },
    align: (x, _) => { if calc.rem(x, 2) == 0 { left } else { right } },
    ..result
  )
}


// 入口函数
#let main(data) = {
  company-header()
  v(-1em)
  align(center)[= 日进出报表]
  v(1em)
  grid(
    columns: (1fr,) * 3,
    align(left)[制表时间：#text(size: 10pt, data.time)],
    align(center)[本月剩余天数：#data.remaining],
    align(right)[单位：人民币万元],
  )
  detail(data)
}

#let data_source = sys.inputs.at("data", default: "cimr500.all.json")  // 数据来源
#let data = json(data_source)
#main(data)

