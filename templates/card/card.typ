// 标签卡片模板：JSON 一笔数据 = 一张卡片 = 一页
// 编译（data 路径相对本模板文件所在目录）：
//   typst compile --root . --font-path isee-core/fonts --font-path fonts \
//     templates/card/card.typ out.pdf --input data=card.json

#import "/lib.typ": report-init
#import "/config.typ": company
#import "@preview/tiaoma:0.3.0": barcode, code128, code39, ean, qrcode

// ============ 页面 ============
#show: report-init
// 卡片尺寸：改这两个值即可换标签规格（内容区 = 尺寸 - 2 × margin）
#let card-width = 100mm
#let card-height = 75mm
#let card-margin = 3mm
#set page(width: card-width, height: card-height, margin: card-margin)

// ============ 字段定义 ============
// (key, 标题)：顺序决定信息区显示顺序；增删字段只动这一处
#let fields = (
  (key: "pn", title: "料号"),
  (key: "spec", title: "规格型号"),
  (key: "lot", title: "批次号"),
  (key: "qty", title: "数量"),
  (key: "production-date", title: "生产日期"),
  (key: "expiry-date", title: "有效期至"),
  (key: "supplier", title: "供应商"),
  (key: "remark", title: "备注"),
)

// 取字段值：空字符串按缺省处理
#let val(data, key, default: none) = {
  let v = data.at(key, default: none)
  if v == none or v == "" { default } else { v }
}

// 字段显示值：数量字段自动带上单位
#let field-value(data, key) = {
  let v = data.at(key)
  if key == "qty" {
    let unit = data.at("unit", default: none)
    if unit != none and unit != "" { return [#v #unit] }
  }
  [#v]
}

// ============ 信息区 ============
#let info(data) = {
  set par(leading: 0.5em) // 收紧行距，字段多时也能留在边框内
  let lines = ()
  for (key, title) in fields {
    let v = data.at(key, default: none)
    if v != none and v != "" {
      lines.push([#title：#field-value(data, key)])
    }
  }
  lines.join(linebreak())
}

// ============ 二维码内容 ============
// 有 qrcode 字段则直接用；否则按 fields 拼成 "标题=值" 的多行文本
#let qr-content(data) = {
  let custom = data.at("qrcode", default: none)
  if custom != none and custom != "" { return str(custom) }
  let parts = ()
  for (key, title) in fields {
    let v = data.at(key, default: none)
    if v != none and v != "" { parts.push(title + "=" + str(v)) }
  }
  parts.join("\n")
}

// ============ 条形码 ============
// barcode-type：code128（默认）/ code39 / ean / qrcode / 其它 zint 名称
// 关闭 zint 自带的人眼可读文本(show-hrt)，码值统一由下方单独绘制，避免重复显示
#let render-barcode(data) = {
  let v = val(data, "barcode", default: val(data, "pn", default: ""))
  if v == "" or v == none { return none }
  let t = val(data, "barcode-type", default: "code128")
  let opts = (show-hrt: false)
  if t == "code128" { code128(v, options: opts) }
  else if t == "code39" { code39(v, options: opts) }
  else if t == "ean" { ean(v, options: opts) }
  else if t == "qrcode" { qrcode(v, options: opts) }
  else { barcode(v, t, options: opts) }
}

// 把条码等比缩放(contain)进固定框，短码不会超高、长码不会超宽，始终留在边框内
#let fit-barcode(data, max-width: 84mm, max-height: 14mm) = {
  let img = render-barcode(data)
  if img == none { return none }
  context {
    let dim = measure(img)
    let s = calc.min(max-width / dim.width, max-height / dim.height)
    box(
      width: max-width,
      height: max-height,
      align(center + horizon)[#scale(x: s * 100%, y: s * 100%, reflow: true)[#img]],
    )
  }
}

// ============ 单张卡片 ============
#let card(data) = {
  let name = val(data, "name", default: "—")
  let company-name = val(data, "company", default: company.name)
  let type-name = val(data, "type", default: "产品标签")
  let barcode-value = val(data, "barcode", default: val(data, "pn", default: ""))

  block(
    width: 100%,
    height: 100%,
    stroke: 0.8pt + black,
    inset: 3mm,
    radius: 1mm,
    [
      #set text(size: 9pt)
      // 抬头：公司名 + 标签类型
      #grid(
        columns: (1fr, auto),
        align: (left, right),
        [#text(size: 9pt, weight: "bold")[#company-name]],
        [#text(size: 8pt)[#type-name]],
      )
      #line(length: 100%, stroke: 0.5pt + black)
      // 品名
      #block(above: 1mm, below: 1mm)[#text(size: 14pt, weight: "bold")[#name]]
      // 信息区 + 二维码
      #grid(
        columns: (1fr, 24mm),
        gutter: 3mm,
        align: (left + top, center + top),
        [#info(data)],
        [
          #qrcode(qr-content(data), width: 22mm)
          #text(size: 7pt)[扫码查看]
        ],
      )
      // 条形码 + 码值（码值只在此处绘制一次，条码本身不含可读文字）
      #align(center)[
        #block(above: 1mm)[#fit-barcode(data)]
        #text(size: 8pt)[#barcode-value]
      ]
    ],
  )
}

// ============ 数据源 ============
// 编译时始终显式传 --input data=...，不依赖这里的缺省文件名
#let data_source = sys.inputs.at("data", default: "card.json")
#let raw = json(data_source)
#let cards = if type(raw) == array { raw } else { (raw,) }
#cards.map(card).join(pagebreak())
