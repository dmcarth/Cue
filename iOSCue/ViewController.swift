//
//  ViewController.swift
//  iOSCue
//
//  Created by Dylan McArthur on 9/18/17.
//  Copyright © 2017 Dylan McArthur. All rights reserved.
//

import UIKit
import cue

class Parser {
	
	init(string: String) {
		let str = string as NSString
		let buffer = UnsafeMutablePointer<UInt16>.allocate(capacity: str.length)
		str.getCharacters(buffer)
		let doc = cue_document_from_utf16(buffer, str.length)
		buffer.deallocate(capacity: str.length)
		cue_document_free(doc)
	}
	
}

class ViewController: UIViewController {

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	@IBAction func benchmarkWarAndPeace(_ sender: UIButton) {
		let url = Bundle.main.url(forResource: "war+peace", withExtension: "txt")!
		let str = try! String(contentsOf: url)
		
		measure {
			_ = Parser(string: str)
		}
	}
	
	@IBAction func benchmarkHamlet(_ sender: UIButton) {
		let url = Bundle.main.url(forResource: "hamlet", withExtension: "txt")!
		let str = try! String(contentsOf: url)
		
		measure {
			_ = Parser(string: str)
		}
	}
	
	func measure(_ block: ()->Void) {
		var clocks: clock_t = 0
		
		for _ in 0..<10 {
			let t1 = clock()
			block()
			let t2 = clock()
			clocks += t2 - t1
		}
		
		let time = (Double(clocks) / 10.0) / Double(CLOCKS_PER_SEC)
		
		print("Operation averaged \(time) seconds.")
	}
	
}

