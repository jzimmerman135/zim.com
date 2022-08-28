
var prismLanguages = [
    'c',
    'clike',
    'markup',
    'glsl',
    'python',
    'javascript',
    'css'
];

prismLanguages = new Map();
prismLanguages.set('c', Prism.languages.c);
prismLanguages.set('clike', Prism.languages.clike);
prismLanguages.set('markup', Prism.languages.markup);
prismLanguages.set('glsl', Prism.languages.glsl);
prismLanguages.set('python', Prism.languages.python);
prismLanguages.set('css', Prism.languages.css);
prismLanguages.set('javascript', Prism.languages.javascript);


function fetchCodeblock(codeblock, language, filepath) {
    fetch(filepath)
    .then(response => response.text())
    .then((src) => {
        // insertCodeblock(codeblock, language, src);
        // Prism.highlightAll();
        manualHighlightCodeblock(codeblock, language, src);
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
    
    
    const prismHighlighter = prismLanguages.get(language);

    codeMarkup = Prism.highlight(src, prismHighlighter, language);
    src = filterArrowsAndAmpersands(src);

    codeblock.className = 'language-' + language;
    codeblock.className += 'manual';
    codeblock.innerHTML = codeMarkup;
}   

function insertCodeblock(codeblock, language, src) {
    if (!prismLanguages.has(language)) {
        console.error(`\'${language}\' language syntax highlighting is not supported`);
        throw 'language not supported';
    } 

    codeblock.className = 'language-' + language;
    codeblock.innerHTML = filterArrowsAndAmpersands(src);
}

