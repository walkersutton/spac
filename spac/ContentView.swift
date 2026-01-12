//
//  ContentView.swift
//  spac
//
//  Created by Walker Sutton on 9/15/25.
//

import SwiftUI

struct ContentView: View {
	var body: some View {
		GeometryReader { proxy in
			let size = proxy.size
			let width = size.width
			let height = size.height

			// Dummy background in place of an image asset
			LinearGradient(colors: [
				Color(red: 0.10, green: 0.15, blue: 0.50),
				Color(red: 0.85, green: 0.10, blue: 0.35),
				Color(red: 0.10, green: 0.60, blue: 0.50)
			], startPoint: .topLeading, endPoint: .bottomTrailing)
				.saturation(1.2)
				.blur(radius: 10)
				.frame(width: width, height: height)
		}
		.ignoresSafeArea()
	}
}

#Preview {
	ContentView()
}
