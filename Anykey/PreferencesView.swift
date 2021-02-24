//
//  ContentView.swift
//  Anykey
//
//  Created by Artem Chistyakov on 2/8/21.
//

import SwiftUI

enum ConfigStatus : Equatable {
    case valid
    case invalid(String)
}

struct PreferencesView: View {
    @State private var configPath: String = UserDefaults.standard.configPath
    dynamic var configStatus: ConfigStatus {
        do {
            _ = try HotkeyConfig(filePath: NSString(string: self.configPath).expandingTildeInPath)
            return .valid
        } catch let error as ConfigError {
            switch error {
            case .access(let description):
                return .invalid(description)
            case .invalid(let description):
                return .invalid(description)
            case .unknown(let description):
                return .invalid(description)
            }
        } catch {
            return .invalid("unknown error")
        }
    }

    var body: some View {
        VStack {
            Form {
                Section(header: Text("Settings").bold()) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Config path:")

                        VStack(alignment: .leading) {
                            TextField(configPathDefault, text: $configPath) { isEditing in
                            } onCommit: {
                                UserDefaults.standard.set(self.configPath, forKey: configPathKey)
                            }

                            switch(self.configStatus) {
                            case .valid:
                                HStack(alignment: .firstTextBaseline, spacing: 3) {
                                    if #available(macOS 11, *) {
                                        Image(systemName: "checkmark.circle.fill")
                                    } else {
                                        Image(decorative: "checkmark.circle.fill")
                                    }
                                    Text("Valid config")
                                }.foregroundColor(Color.green)
                            case .invalid(let error):
                                HStack(alignment: .firstTextBaseline, spacing: 3) {
                                    if #available(macOS 11, *) {
                                        Image(systemName: "xmark.circle.fill")
                                    } else {
                                        Image(decorative: "xmark.circle.fill")
                                    }
                                    Text("Error: \(error)")
                                }.foregroundColor(Color.red)
                            }
                        }
                    }
                }
            }
                .padding(20)
                .frame(maxWidth: 800, maxHeight: .infinity)

            Divider()

            VStack {
                Text("Created by Artem Chistyakov, 2021")

                if #available(macOS 11, *) {
                    Link("temochka.com", destination: URL(string: "https://temochka.com")!).padding(5)
                } else {
                    Text("https://temochka.com").padding(5)
                }
            }
        }.padding(5)
    }

}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}
