// A4 标签模板：标签从上到下排列（列优先），一页排不下自动换页
// 编译（data 路径相对本模板文件所在目录）：
//   typst compile --root . --font-path isee-core/fonts --font-path fonts \
//     templates/card/card-top-down.typ out.pdf --input data=card.json

#import "/lib.typ": report-init
#import "/config.typ": company
#import "@preview/tiaoma:0.3.0": barcode, code128, code39, ean, qrcode

// ============ 页面：固定 A4 ============
#show: report-init
#let page-margin = 10mm
#set page(paper: "a4", margin: page-margin)

// ============ 标签规格（可调） ============
// 每行标签数按 A4 宽度自动计算；改标签宽/高/间距即可换排版密度
#let label-width = 45mm
#let label-height = 32mm
#let label-gutter = 3mm
#let a4-width = 210mm
#let cols = calc.floor((a4-width - 2 * page-margin + label-gutter) / (label-width + label-gutter))

// ============ 字段定义（同 card.typ） ============
// (key, 标题)：顺序决定二维码内容里的字段顺序
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

// 等比缩放(contain)进固定框，短码不超高、长码不超宽，始终留在边框内
#let fit-barcode(data, max-width, max-height) = {
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

// ============ 单张标签（固定尺寸，精简布局） ============
#let label(data) = {
  let name = val(data, "name", default: "—")
  let pn = val(data, "pn", default: "")
  let qty = val(data, "qty", default: "")
  let unit = val(data, "unit", default: "")
  let lot = val(data, "lot", default: "")
  let barcode-value = val(data, "barcode", default: pn)

  block(
    width: label-width,
    height: label-height,
    stroke: 0.6pt + black,
    inset: 1.5mm,
    radius: 1mm,
    [
      #set text(size: 7pt)
      #block(below: 0.5mm)[#text(size: 8pt, weight: "bold")[#name]]
      #block(below: 0.5mm)[料号：#pn]
      #block(below: 0.5mm)[数量：#qty #unit]
      #if lot != "" [#block(below: 0.5mm)[批次：#lot]]
      #block(above: 1mm)[
        #grid(
          columns: (30mm, 10mm),
          gutter: 2mm,
          align: (center + horizon, center + horizon),
          [
            #fit-barcode(data, 29mm, 10mm)
            #text(size: 6pt)[#barcode-value]
          ],
          [#qrcode(qr-content(data), width: 10mm)],
        )
      ]
    ],
  )
}

// ============ 数据源 ============
// 编译时始终显式传 --input data=...，不依赖这里的缺省文件名
#let data_source = sys.inputs.at("data", default: "card.json")
#let raw = json(data_source)
#let cards = if type(raw) == array { raw } else { (raw,) }

// ============ 列优先排版 ============
// 每列的标签数：按 A4 可用高度计算
#let page-height = 297mm
#let rows-per-col = calc.floor((page-height - 2 * page-margin + label-gutter) / (label-height + label-gutter))

// 单列：从上到下竖直排列
#let column-block(group) = {
  grid(
    rows: (label-height,) * group.len(),
    gutter: label-gutter,
    ..group.map(label),
  )
}

// 外层按列从左到右排布，放不下的列自动续到下一页
#grid(
  columns: (label-width,) * cols,
  gutter: label-gutter,
  ..cards.chunks(rows-per-col).map(column-block),
)
