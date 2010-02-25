#set key top right
unset key

set xrange [0:1]
set yrange [0:16]

set xlabel "Clustering Coefficient"
set ylabel "Diameter"

set title "Clustering Coefficient - Diameter"

set output "stat_cc_diameter.eps"
set size 2,2
set terminal postscript eps color enhanced solid 40

plot "../../data/all_average.txt" using 6:1 title "All" lw 10 lc 1 with points
