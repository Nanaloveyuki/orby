const childProcess = require("child_process");

function pkgConfig(args) {
  return childProcess.execFileSync("pkg-config", args, { encoding: "utf8" }).trim();
}

const vars = {
  ORBY_GTK_STUB_CC_FLAGS: "",
  ORBY_GTK_CC_LINK_FLAGS: "",
};
const link_configs = [];

if (process.platform === "win32") {
  link_configs.push({
    package: "Nanaloveyuki/orby/windows",
    link_flags: "user32.lib gdi32.lib ole32.lib shcore.lib",
  });
} else if (process.platform === "linux") {
  try {
    vars.ORBY_GTK_STUB_CC_FLAGS = pkgConfig(["--cflags", "gtk+-3.0"]);
    vars.ORBY_GTK_CC_LINK_FLAGS = pkgConfig(["--libs", "gtk+-3.0"]);
  } catch (_) {
    throw new Error("orby requires GTK3 development files discoverable through pkg-config");
  }
  link_configs.push({
    package: "Nanaloveyuki/orby/linux",
    link_flags: vars.ORBY_GTK_CC_LINK_FLAGS,
  });
}

console.log(JSON.stringify({ vars, link_configs }));
