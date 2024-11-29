//
//  SettingsView.swift
//  Ez Unzip
//
//  Created by kkxx on 2024/11/29.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
           VStack {
               Text("Settings")
                   .font(.headline)
                   .padding()
               Text("Here you can configure global settings for Ez Unzip.")
                   .foregroundColor(.gray)
                   .padding()
           }
           .frame(width: 300, height: 200)
       }
}

#Preview {
    SettingsView()
}
