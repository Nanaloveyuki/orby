name = "Nanaloveyuki/orby"

version = "0.1.0-beta.9"

description = "Native MoonBit application and window host."

repository = "https://github.com/Nanaloveyuki/orby"

license = "Apache-2.0"

readme = "README.md"

keywords = [ "moonbit", "windowing", "win32", "gtk" ]

preferred_target = "native"

source = "src"

import {
  "Nanaloveyuki/moonview@0.1.0-beta.14",
  "Nanaloveyuki/parsec@0.1.7",
}

options(
  "--moonbit-unstable-prebuild": "build.js",
)
