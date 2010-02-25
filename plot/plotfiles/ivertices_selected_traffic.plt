#set key top left
unset key

set xrange [0:10]
set yrange [0:10]

set xlabel "Number of Inner Vertices"
set ylabel "Traffic in KiB"

set title "Selected Topologies (Inner Vertices - Traffic)"

set output "ivertices_selected_traffic.eps"
set size 2,2
set terminal postscript eps color enhanced solid 40

plot "../data/selected_leaves_avg.txt" using 4:18 title "Average" lw 5 lc 3 with lines
