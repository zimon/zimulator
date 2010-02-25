set key top left
#unset key

set xrange [2:31]
set yrange [0:35]

set xlabel "Number of Vertices"
set ylabel "Convergence Time in Seconds"

set title "Circle and Row Topologies (Vertices - Time)"

set output "vertices_circle_row_time.eps"
set size 2,2
set terminal postscript eps color enhanced solid 40

plot "../data/circle_average.txt" using 2:9 title "Circle" lw 5 lc 1 with lines, "../data/row_average.txt" using 2:9 title "Row" lw 5 lc 3 with lines
