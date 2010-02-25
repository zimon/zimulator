#set key top left
unset key

set xrange [9:17]
set yrange [0:35]

set xlabel "Number of Vertices"
set ylabel "Traffic in KiB"

set title "Selected Topologies (Vertices - Traffic)"

set output "vertices_selected_traffic.eps"
set size 2,2
set terminal postscript eps color enhanced solid 40

plot "../data/const_vertices_average.txt" using 2:18 title "average" lw 5 lc 3 with lines
