
const prismLanguages = [
    'c',
    'clike',
    'markup',
    'glsl',
    'python',
    'javascript',
    'css'
];

function fetchCodeblock(codeblock, language, filepath) {
    fetch(filepath)
    .then(response => response.text())
    .then((src) => {
        insertCodeblock(codeblock, language, src);
        Prism.highlightAll();
    });
}

function filterArrowsAndAmpersands(src) {
    src = src.replace(/&/g, '&amp;');
    src = src.replace(/</g, '&lt;');
    src = src.replace(/>/g, '&gt;');
    return src
}

function manualHighlightCodeblock(codeblock, language, src) {
    if (!prismLanguages.has(language)) {
        console.error(`\'${language}\' language syntax highlighting is not supported`);
        throw 'language not supported'
    }
    
    src = filterArrowsAndAmpersands(src);
    const prismHighlighter = prismLanguages.get(language);

    codeMarkup = Prism.highlight(src, prismHighlighter, language)

    codeblock.className = 'language-' + language;
    codeblock.innerHTML = codeMarkup;
}   

function insertCodeblock(codeblock, language, src) {
    if (!prismLanguages.includes(language)) {
        console.error(`\'${language}\' language syntax highlighting is not supported`);
        throw 'language not supported';
    } 

    codeblock.className = 'language-' + language;
    codeblock.innerHTML = filterArrowsAndAmpersands(src);
}

