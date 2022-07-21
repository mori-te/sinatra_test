import katex from 'https://cdn.jsdelivr.net/npm/katex@0.16.0/dist/katex.mjs';
import {marked} from "https://unpkg.com/marked@4.0.18/src/marked.js";

export {compiledMarkdownAndKatex};

function compiledMarkdownAndKatex({question}) {
    const placeholder = "[katex][/katex]";
    const re = /\$\$ *([^\$\n]*) *\$\$/g;
    var expressions = [];
    var matches;
    var text = question;
    while ((matches = re.exec(text)) != null) {
        expressions.push(matches);
    }
    for (const expression of expressions) {
        text = text.replace(expression[0], placeholder);
    }
    var markdown = marked(text, { sanitize: true });
    for (const expression of expressions) {
        var exprText = null;
        try {
            exprText = katex.renderToString(expression[1])
        } catch (e) {
            exprText = e.message;
        }
        markdown = markdown.replace(placeholder, exprText);
    }
    return markdown;
};
