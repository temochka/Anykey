//
//  ContentView.swift
//  Anykey
//
//  Created by Artem Chistyakov on 2/8/21.
//

import SwiftUI
import Combine

enum ConfigStatus : Equatable {
    case valid
    case invalid(String)
}

final class Preferences : ObservableObject {
    @Published var hideFromStatusBar: Bool = UserDefaults.standard.hideFromStatusBar {
        didSet {
            UserDefaults.standard.set(hideFromStatusBar, forKey: hideFromStatusBarKey)
        }
    }

    var configPath: String = UserDefaults.standard.configPath {
        didSet {
            UserDefaults.standard.set(configPath, forKey: configPathKey)
        }
    }
}

struct PreferencesView: View {
    @ObservedObject var preferences = Preferences()
    @State private var configPathText: String = UserDefaults.standard.configPath

    dynamic var configStatus: ConfigStatus {
        do {
            _ = try HotkeyConfig(filePath: NSString(string: self.configPathText).expandingTildeInPath)
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
                        Text("Config path:").frame(width: 100, alignment: .leading)

                        VStack(alignment: .leading) {
                            TextField(configPathDefault, text: $configPathText) { _ in
                            } onCommit: {
                                self.preferences.configPath = self.configPathText
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

                    HStack(alignment: .center) {
                        Toggle("Hide Anykey from status bar", isOn: $preferences.hideFromStatusBar)
                            .padding(.leading, 106)
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
            }.padding()
        }.padding(5)
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}
