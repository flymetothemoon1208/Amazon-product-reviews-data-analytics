import CoreGraphics
import Foundation
import ImageIO

let args = CommandLine.arguments

guard args.count >= 3 else {
  fputs("Usage: swift render_pdf_pages.swift <input.pdf> <output-dir> [target-width]\n", stderr)
  exit(2)
}

let inputURL = URL(fileURLWithPath: args[1])
let outputURL = URL(fileURLWithPath: args[2], isDirectory: true)
let targetWidth = args.count >= 4 ? Double(args[3]) ?? 1400 : 1400

try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

guard let document = CGPDFDocument(inputURL as CFURL) else {
  fputs("Unable to open PDF: \(inputURL.path)\n", stderr)
  exit(1)
}

let colorSpace = CGColorSpaceCreateDeviceRGB()
let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

for pageNumber in 1...document.numberOfPages {
  guard let page = document.page(at: pageNumber) else { continue }

  let pageBox = page.getBoxRect(.mediaBox)
  let scale = targetWidth / pageBox.width
  let width = Int((pageBox.width * scale).rounded())
  let height = Int((pageBox.height * scale).rounded())

  guard
    let context = CGContext(
      data: nil,
      width: width,
      height: height,
      bitsPerComponent: 8,
      bytesPerRow: 0,
      space: colorSpace,
      bitmapInfo: bitmapInfo
    )
  else {
    fputs("Unable to create image context for page \(pageNumber)\n", stderr)
    continue
  }

  context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
  context.fill(CGRect(x: 0, y: 0, width: width, height: height))
  context.saveGState()
  let targetRect = CGRect(x: 0, y: 0, width: width, height: height)
  context.concatenate(page.getDrawingTransform(.mediaBox, rect: targetRect, rotate: 0, preserveAspectRatio: true))
  context.drawPDFPage(page)
  context.restoreGState()

  guard let image = context.makeImage() else {
    fputs("Unable to create PNG for page \(pageNumber)\n", stderr)
    continue
  }

  let filename = String(format: "page-%02d.png", pageNumber)
  let destinationURL = outputURL.appendingPathComponent(filename)

  guard let destination = CGImageDestinationCreateWithURL(
    destinationURL as CFURL,
    "public.png" as CFString,
    1,
    nil
  ) else {
    fputs("Unable to create destination for \(filename)\n", stderr)
    continue
  }

  CGImageDestinationAddImage(destination, image, nil)
  if !CGImageDestinationFinalize(destination) {
    fputs("Unable to write \(filename)\n", stderr)
  }
}

print("Rendered \(document.numberOfPages) page(s)")
