#set key top right
unset key

set xrange [0:51]
set yrange [0:101]

set xlabel "Number of Vertices"
set ylabel "Number of Edges"


set title "Vertices - Edges"

set output "stat_vertices_edges.eps"
set size 2,2
set terminal postscript eps color enhanced solid 40

plot "../../data/all_average.txt" using 2:5 title "All" lw 10 lc 1 with points
