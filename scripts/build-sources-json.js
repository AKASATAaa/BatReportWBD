/**
 * Bat 루트의 En / JP / 리그전 / 오야저야 폴더를 스캔해 sources.json 생성
 * (전부다합친거 등은 제외)
 */
const fs = require("fs");
const path = require("path");

const BAT = path.join(__dirname, "..");
const SOURCE_IDS = ["En", "JP", "리그전", "오야저야"];

function isMergeable(name) {
  const n = String(name || "").toLowerCase();
  if (/^index\.csv$/i.test(n)) return false;
  if (/\.(csv|txt)$/i.test(n)) return true;
  return n.indexOf(".") === -1;
}

function listFiles(dir) {
  if (!fs.existsSync(dir)) return [];
  return fs
    .readdirSync(dir)
    .filter((name) => {
      try {
        return fs.statSync(path.join(dir, name)).isFile() && isMergeable(name);
      } catch {
        return false;
      }
    })
    .sort((a, b) => a.localeCompare(b, "ko"));
}

const sources = SOURCE_IDS.map(function (id) {
  return {
    id: id,
    label: id,
    files: listFiles(path.join(BAT, id)),
  };
});

const out = {
  indexCsv: "Index.csv",
  sources: sources,
};

fs.writeFileSync(
  path.join(BAT, "sources.json"),
  JSON.stringify(out, null, 2),
  "utf8"
);

console.log("[build-sources-json] wrote sources.json");
sources.forEach(function (s) {
  console.log("  " + s.id + ": " + s.files.length + " files");
});
