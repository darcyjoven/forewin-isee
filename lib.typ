// core

#import "/isee-core/lib.typ": *


// 常用格式定义

// code 说明文档
#let code-init(body) = {
  set page(paper: "a4", height: auto)
  show: ctypset
  set text(font: code) // 覆盖正文拉丁文字为等宽字体
  show: fakebold // 伪粗体
  set-num(math: false)
  body
}
// report 报表
#let report-init(body) = {
  set page(paper: "a4")
  show: ctypset
  set text(font: financial)
  set-round(
    pad: true,
    direction: "nearest",
    ties: "away-from-zero",
    mode: "places",
  )
  set-group(
    separator: ",",
    size: 3,
    threshold: 4,
  )
  set-num(math: false)
  show: fakebold

  body
}
