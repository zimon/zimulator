#set key top left
unset key

set xrange [1:11]
set yrange [0:10]

set xlabel "Number of Leaves"
set ylabel "Traffic in KiB"

set title "Selected Topologies (Leaves - Traffic)"

set output "leaves_selected_traffic.eps"
set size 2,2
set terminal postscript eps color enhanced solid 40

plot "../data/selected_leaves_avg.txt" using 3:18 title "average" lw 5 lc 3 with lines
