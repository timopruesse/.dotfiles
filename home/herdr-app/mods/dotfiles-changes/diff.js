const wideGlyph = /[\p{Ideographic}\p{Emoji_Presentation}\p{Extended_Pictographic}\u1100-\u115f\u2e80-\ua4cf\uac00-\ud7a3\ufe10-\ufe19\ufe30-\ufe6f\uff01-\uff60\uffe0-\uffe6]/gu;

// Keep room for spacing marks and give wide glyphs at least two columns.
export function displayColumns(text) {
  let columns = text.length;
  for (const glyph of text.match(wideGlyph) ?? []) {
    if (glyph.length === 1) columns++;
  }
  return columns;
}

// GPUI draws a tab as nothing. Expand it before splitting into styled runs.
function untab(text) {
  return text.replace(/[^\t]*\t/g, (part) => {
    const prefix = part.slice(0, -1);
    return prefix + " ".repeat(4 - displayColumns(prefix) % 4);
  });
}

const double = String.raw`"(?:\\.|[^"\\])*"`;
const single = String.raw`'(?:\\.|[^'\\])*'`;
const backtick = String.raw`\x60(?:\\.|[^\x60\\])*\x60?`;
const quoted = `${double}?|${single}?`;
const cComment = String.raw`//.*|/\*[^]*?(?:\*/|$)`;
const hash = "#.*";
const number = String.raw`(?:0[xX][\da-fA-F_]+|0[bB][01_]+|0[oO][0-7_]+|\d[\d_]*(?:\.[\d_]+)?(?:[eE][+-]?[\d_]+)?)`;
const word = String.raw`[$_\p{ID_Start}][\p{ID_Continue}$]*`;
const grammars = new Map();

function grammar(extensions, { comments, strings = quoted, key, keywords = "", types = false, typeNames = "", calls = false }) {
  const patterns = [`(?<string>${strings})`, `(?<number>${number})`, `(?<word>${word})`];
  if (key) patterns.unshift(`(?<key>${key})`);
  if (comments) patterns.unshift(`(?<comment>${comments})`);
  const language = { pattern: new RegExp(patterns.join("|"), "gu"), keywords: new Set(keywords.split(" ")), types, typeNames: new Set(typeNames.split(" ")), calls };
  for (const extension of extensions.split(" ")) grammars.set(extension, language);
}

const js = {
  comments: cComment, strings: `${quoted}|${backtick}`, types: true, calls: true,
  keywords: "as async await break case catch class const continue debugger declare default delete do else enum export extends false finally for from function if implements import in infer instanceof interface keyof let namespace new null of private protected public readonly return satisfies static super switch this throw true try type typeof undefined var void while with yield",
};
grammar("js mjs cjs jsx", js);
grammar("ts mts cts tsx", { ...js, typeNames: "any bigint boolean never number object string symbol unknown" });
grammar("py pyi", {
  comments: hash, types: true, calls: true,
  keywords: "and as assert async await break case class continue def del elif else except False finally for from global if import in is lambda match None nonlocal not or pass raise return True try while with yield",
});
grammar("lua", {
  comments: String.raw`--(?:\[\[[^]*?(?:\]\]|$)|.*)`, calls: true,
  keywords: "and break do else elseif end false for function goto if in local nil not or repeat return then true until while",
});
grammar("sh bash zsh .bashrc .zshrc .zprofile .profile", {
  comments: String.raw`(?<![^ \t;()|&])#.*`, strings: `${quoted}|${backtick}`,
  keywords: "case do done elif else esac export fi for function if in local readonly set then until while",
});
grammar("rs go c h cc cpp cxx hh hpp java swift kt cs", {
  comments: cComment, types: true, calls: true,
  keywords: "as async await bool break case catch char class const continue default defer do double else enum extern false fn float for func guard if impl import in int interface let long match mod mut namespace new nil null package private protected pub public return self short static struct super switch throw trait true try type typedef unsafe use using var void while yield",
});
const json = { strings: `${double}?`, key: `${double}(?=\\s*:)`, keywords: "true false null" };
grammar("json", json);
grammar("jsonc", { ...json, comments: cComment });
grammar("yaml yml toml", {
  comments: hash, key: `(?:${double}|${single}|(?<![\\w.-])[\\w.-]+)(?=\\s*(?::(?:\\s|$)|=))`, keywords: "true false null",
});

function languageFor(path) {
  const name = path.split(/[\\/]/).at(-1).toLowerCase();
  return grammars.get(name) ?? grammars.get(name.slice(name.lastIndexOf('.') + 1));
}

const MAX_SPANS = 96;
function highlight(text, language) {
  const plain = () => [{ text, role: "plain" }];
  if (!language) return plain();
  const spans = [];
  const append = (value, role) => {
    if (!value) return;
    const last = spans.at(-1);
    if (last?.role === role) last.text += value;
    else spans.push({ text: value, role });
  };
  let end = 0;
  for (const match of text.matchAll(language.pattern)) {
    append(text.slice(end, match.index), "plain");
    end = match.index + match[0].length;
    const { comment, key, string, number, word } = match.groups;
    let role = "plain";
    if (comment) role = "comment";
    else if (key) role = "key";
    else if (string) role = "string";
    else if (number) role = "number";
    else if (language.keywords.has(word)) role = "keyword";
    else if (language.typeNames.has(word) || (language.types && /^[A-Z]/.test(word))) role = "type";
    else if (language.calls && /^[ \t]*\(/.test(text.slice(end))) role = "function";
    append(match[0], role);
    if (spans.length >= MAX_SPANS) return plain();
  }
  append(text.slice(end), "plain");
  return spans.length ? spans : plain();
}

// Hunks can start inside a string or comment without the preceding lines.
export function diffRows(lines, path = "") {
  const language = languageFor(path);
  let old = 0, next = 0;
  return lines.map((line) => {
    const match = /^@@ -(\d+)(?:,\d+)? \+(\d+)/.exec(line);
    if (match) { old = +match[1]; next = +match[2]; return { kind: "@", text: line }; }
    const kind = line[0];
    if (kind !== "-" && kind !== "+" && kind !== " ") return { kind: "", text: line };
    const number = kind === "-" ? old++ : next++;
    if (kind === " ") old++;
    const text = untab(line.slice(1));
    return { kind, number, text, spans: highlight(text, language) };
  });
}

const syntax = {
  dark: { keyword: "#d7afff", string: "#ffd58a", number: "#9cbdff", type: "#91d9fa", function: "#7fd9ee", key: "#91d9fa", comment: "#abbad2" },
  light: { keyword: "#6b2eaa", string: "#794600", number: "#274fa7", type: "#005c80", function: "#006075", key: "#005c80", comment: "#515d74" },
};

function rgb(color) {
  return [1, 3, 5].map((offset) => parseInt(color.slice(offset, offset + 2), 16) / 255);
}

function luminance(color) {
  const linear = rgb(color).map((c) => c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4);
  return linear[0] * 0.2126 + linear[1] * 0.7152 + linear[2] * 0.0722;
}

function mix(base, tint, amount) {
  const target = rgb(tint);
  return "#" + rgb(base).map((c, i) => Math.round((c + (target[i] - c) * amount) * 255).toString(16).padStart(2, "0")).join("");
}

export function diffPalette(theme) {
  const { background, foreground, ansi1, ansi2, accent } = theme;
  const dark = luminance(background) < 0.179;
  const surface = {
    "+": mix(background, ansi2, dark ? 0.16 : 0.13),
    "-": mix(background, ansi1, dark ? 0.16 : 0.13),
    "@": mix(background, accent, 0.1),
    " ": background,
  };
  return Object.fromEntries(Object.entries(surface).map(([kind, bg]) => {
    const base = luminance(bg);
    const readable = (...colors) => colors.find((color) => {
      const value = luminance(color);
      return (Math.max(base, value) + 0.05) / (Math.min(base, value) + 0.05) >= 4.5;
    }) ?? (base < 0.179 ? "#ffffff" : "#000000");
    const plain = readable(foreground);
    let marker = plain;
    if (kind === "+") marker = readable(ansi2, dark ? "#a7d7ae" : "#246239", plain);
    if (kind === "-") marker = readable(ansi1, dark ? "#ffb0b5" : "#a12839", plain);
    const tokens = Object.fromEntries(Object.entries(syntax[dark ? "dark" : "light"])
      .map(([role, color]) => [role, readable(color, plain)]));
    return [kind, { bg, marker, gutter: readable(mix(bg, plain, 0.72), plain), hunk: readable(accent, tokens.number, plain), tokens: { plain, ...tokens } }];
  }));
}
