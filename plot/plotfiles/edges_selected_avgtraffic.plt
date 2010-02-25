#set key top left
unset key

#set xrange [8:28]
#set yrange [0:35]

set xlabel "Number of Edges"
set ylabel "Average Traffic per Net in KiB"

set title "Selected Topologies (Egdes - Average Traffic per Net)"

set output "edges_selected_avgtraffic.eps"
set size 2,2
set terminal postscript eps color enhanced solid 40

plot "../data/const_edges_avg.txt" using 5:19 title "average" lw 5 lc 3 with lines
