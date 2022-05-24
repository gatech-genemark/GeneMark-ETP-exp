#!/usr/bin/env gnuplot
#
# Tomas Bruna
#

set title "{/:Italic ".title."}"
set datafile separator ','
set key outside bottom center
set key spacing 1.5
unset key
set xlabel "Specificity"
set ylabel "Sensitivity"


set mxtics 2
set mytics 2

set grid xtics ytics mxtics mytics lt 0 lw 1, lt rgb "#bbbbbb" lw 1


set term pdf
set style data lp

set output "tsebra.".species.".".distance.".".type.".pdf"

set size ratio -1

set xrange [x1:x2]
set yrange [y1:y2]

# Colors: http://colorbrewer2.org/#type=qualitative&scheme=Set1&n=7

braker1(x) = -x + braker1i
braker2(x) = -x + braker2i
tsebra(x) = -x + tsebrai
etp(x) = -x + etpi

b1Color = "#000000"
b2Color = "#000000"
tColor = "#000000"
etpColor = "#e41a1c"

subgenusColor = "#a65628"
genusColor = "#377eb8"

orderColor = "#984ea3"
phylumColor = "#ff7100"

pointWidth = 3
pointSize = 1

plot "braker1.".type.".acc" using 2:1 title "BRAKER1" w p pt 12 lw pointWidth ps pointSize lt rgb b1Color, \
     "braker2.".type.".acc" using 2:1 title "BRAKER2" w p pt 1 lw pointWidth ps pointSize + 0.2 lt rgb b2Color, \
     "tsebra.".type.".acc" using 2:1 title "TSEBRA" w p pt 6 lw pointWidth ps pointSize -0.05 lt rgb tColor, \
     "etp.".type.".acc" using 2:1  title "ETP" w p pt 2 lw pointWidth ps pointSize lt rgb etpColor, \
     braker1(x) title 'BRAKER1' with lines linestyle 1 dt 2 lt rgb b1Color, \
     braker2(x) title 'BRAKER2' with lines linestyle 1 dt 2 lt rgb b2Color, \
     etp(x) title 'ETP' with lines linestyle 1 dt 2 lt rgb etpColor, \
     tsebra(x) title 'TSEBRA' with lines linestyle 1 dt 2 lt rgb tColor
