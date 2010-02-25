#set key top left
unset key

#set xrange [8:28]
#set yrange [0:35]

set xlabel "Number of Edges"
set ylabel "Traffic in KiB"

set title "Selected Topologies (Egdes - Traffic)"

set output "edges_selected_traffic.eps"
set size 2,2
set terminal postscript eps color enhanced solid 40

plot "../data/const_edges_avg.txt" using 5:18 title "average" lw 5 lc 3 with lines
