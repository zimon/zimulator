#set key top right
unset key

set xrange [1:80]
set yrange [1:101]

set xlabel "Number of Cycles"
set ylabel "Number of Edges"

set title "Cycles - Edges"

set output "stat_cycles_edges.eps"
set size 2,2
set terminal postscript eps color enhanced solid 40

plot "../../data/all_average.txt" using ($5-$2+1):5 title "All" lw 10 lc 1 with points
