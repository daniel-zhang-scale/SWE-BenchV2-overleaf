#!/bin/bash
# Build + verification for the NAACL 2027 Industry Track draft. Usage: ./build.sh
set -e
cd "$(dirname "$0")"
export PATH=/Library/TeX/texbin:$PATH
GREP=/usr/bin/grep
run() { pdflatex -interaction=nonstopmode -halt-on-error main.tex >/dev/null || { echo "pdflatex failed; see main.log"; $GREP -n -A3 "^!" main.log | head -40; exit 1; }; }
run; bibtex main >/dev/null || true; run; run
echo "== pages: $(pdfinfo main.pdf 2>/dev/null | $GREP Pages || python3 -c "import re;print('Pages:',len(re.findall(rb'/Type\s*/Page[^s]',open('main.pdf','rb').read())))")"
LIM=$($GREP -o '\\newlabel{sec:limitations}{{[^}]*}{[0-9]*}' main.aux | $GREP -o '{[0-9]*}$' | tr -d '{}')
echo "== Limitations section starts on page: ${LIM:-?} (must be <= 7, i.e. body ends on p.6)"
echo "== overfull hbox: $($GREP -c 'Overfull .hbox' main.log || true)   overfull vbox: $($GREP -c 'Overfull .vbox' main.log || true)"
echo "== undefined refs/citations: $($GREP -c 'undefined' main.log || true)   multiply defined: $($GREP -c 'multiply defined' main.log || true)"
echo "== bibtex warnings: $($GREP -c 'Warning--' main.blg 2>/dev/null || true)"
echo "== anonymity check (must be empty):"; $GREP -rniE "scale ?ai|scaleapi" main.tex sections appendix tables refs.bib || true
echo "== pending placeholders:"; $GREP -rnE 'PENDING|[\]todo[{]|[\]dyz[{]' tables/numbers.tex sections appendix figures | $GREP -v newcommand || true
$GREP -q 'usepackage\[review\]{acl}' main.tex && echo "== review mode: on"
