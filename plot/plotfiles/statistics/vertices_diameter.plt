#set key top right
unset key

set xrange [1:51]
set yrange [0:16]

set xlabel "Number of Vertices"
set ylabel "Diameter"

set title "Vertices - Diameter"

set output "vertices_diameter.eps"
set size 2,2
set terminal postscript eps color enhanced solid 40

plot "../../data/all_average.txt" using 2:1 title "All" lw 10 lc 1 with points
