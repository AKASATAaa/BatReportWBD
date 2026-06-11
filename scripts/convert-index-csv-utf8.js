const fs = require("fs");
const path = require("path");

const csvPath = path.join(__dirname, "..", "Index.csv");
const buf = fs.readFileSync(csvPath);
const text = new TextDecoder("windows-949").decode(buf);
fs.writeFileSync(csvPath, "\uFEFF" + text.replace(/^\uFEFF/, ""), "utf8");
console.log("Index.csv converted to UTF-8");
