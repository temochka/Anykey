#!/usr/bin/env ruby

# A script to generate a test config with all known modifiers and keys.
# Eventually, it would be nice to test all combinations, but this is
# good enough for now.

require 'json'
require 'securerandom'

VALID_MODIFIERS = {
  option: %w(option opt alt ⌥),
  command: %w(command cmd ⌘),
  control: %w(control ctrl ⌃),
  shift: %w(shift ⇧),
  function: %w(function fn),
}.freeze

VALID_KEYS = [
  ('a'..'z').to_a,
  ('A'..'Z').to_a,
  ('0'..'9').to_a,
  %w(zero one two three four five six seven eight nine),
  ['rightBracket', ']'],
  ['leftBracket', '['],
  ['quote', '"'],
  ['semicolon', ';'],
  ['backslash', "\\"],
  ['comma', ','],
  ['slash', '/'],
  ['period', '.'],
  ['grave', '`', 'ˋ', '｀'],
  %w(keypaddecimal keypadmultiply keypadplus keypadclear keypaddivide keypadenter keypadminus keypadequals),
  Array.new(10) { |i| "keypad#{i}" },
  ["return", "\r", "↩︎", "⏎", "⮐"],
  ["tab", "\t", "⇥"],
  ["space", " ", "␣"],
  ["delete", "⌫"],
  ["escape", "⎋"],
  ["command", "⌘", ""],
  ["shift", "⇧"],
  ["capslock", "⇪"],
  ["option", "⌥"],
  ["control", "⌃"],
  ["rightcommand"],
  ["rightshift"],
  ["rightoption"],
  ["rightcontrol"],
  ["function", "fn"],
  Array.new(20) { |i| ["f#{i+1}", "F#{i+1}"] }.flatten,
  ["volumeup", "🔊"],
  ["volumedown", "🔉"],
  ["mute", "🔇"],
  ["help", "?⃝"],
  ["home", "↖"],
  ["pageup", "⇞"],
  ["forwarddelete", "⌦"],
  ["end", "↘"],
  ["pagedown", "⇟"],
  ["leftarrow", "←"],
  ["rightarrow", "→"],
  ["downarrow", "↓"],
  ["uparrow", "↑"],
].flatten.freeze

$id = 0

def hotkey(attributes)
  $id += 1
  {
    title: "Hotkey #{$id}",
    shellCommand: "say \"hotkey number #{$id}\"",
    key: "/",
    modifiers: ["cmd"],
  }.merge(attributes)
end

config = {
  workingDirectory: '/',
  hotkeys: [
    *VALID_MODIFIERS.values.flatten.map { |m| hotkey(key: '/', modifiers: [m]) },
    hotkey(key: '/', modifiers: VALID_MODIFIERS.values.flatten),
    *VALID_KEYS.map { |k| hotkey(key: k) },
    hotkey(displayNotification: true),
    hotkey(workingDirectory: "~/Downloads"),
    hotkey(onlyIn: ["com.temochka.Anykey"])
  ]
}


puts JSON.pretty_generate(config)

