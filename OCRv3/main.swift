//
//  main.swift
//  OCRv3
//
//  Created by Avi on 2023-11-17.
//

import Vision
import Foundation
struct Output: Codable {
    var imageHeight: Int = 0
    var imageWidth: Int = 0
    var recognizedStrings: [RecognizedStrings] = []
}



guard VNRecognizeTextRequest.currentRevision == 3 else {
    fatalError("OCR revision doesn't match hardcoded version.")
}

guard CommandLine.arguments.endIndex == 2 else {
    fatalError("Wrong number of arguments.")
}
let url = NSURL.fileURL(withPath: CommandLine.arguments[1])
let requestHandler = VNImageRequestHandler(url: url)

let image = CGImageSourceCreateWithURL(url as CFURL, nil)!
let props  = CGImageSourceCopyPropertiesAtIndex(image, 0, nil)! as NSDictionary

let imageHeight = props["PixelHeight"] as! Int + 1
let imageWidth = props["PixelWidth"] as! Int + 1
let encoder = JSONEncoder()
encoder.outputFormatting = .prettyPrinted

// Create a new request to recognize text.
let request = VNRecognizeTextRequest()



try! requestHandler.perform([request])
let observations = request.results!

struct RecognizedStrings: Codable {
    let string: String
    let confidence: VNConfidence
    let segments: [Segment]
}
struct Segment: Codable {
    var str: String = String()
    var start: Int = 0
    var end: Int = 0
    var bounds: CGRect
    
}


let recognizedStrings: [RecognizedStrings] = observations.map { observation in
    let candidate = (observation ).topCandidates(1).first!
    let str = candidate.string
    let sIndex = str.startIndex
    
    var boxLast =  CGRect() // Sentinel default
    var segments: [Segment] = []
    for index in 0..<str.count {
        let singleCharRange = str.index(sIndex, offsetBy: index)..<str.index(sIndex, offsetBy: index + 1)
        let box = try! candidate.boundingBox(for: singleCharRange)!.boundingBox
        
        if boxLast != box { // Edge case if first bound matches sentinel
            segments.append(Segment(start: index, bounds: box))
        }
        boxLast = box
        
        segments[segments.endIndex-1].str.append(contentsOf: str[singleCharRange])
        segments[segments.endIndex-1].end = index
      
    }

    return RecognizedStrings(string: candidate.string, confidence: candidate.confidence, segments: segments)
    
}






let out = Output(imageHeight: imageHeight, imageWidth: imageWidth, recognizedStrings: recognizedStrings)

let data = try encoder.encode(out)
print(String(data: data, encoding: .utf8)!)







