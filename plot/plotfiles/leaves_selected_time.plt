#set key top left
unset key

set xrange [1:11]
set yrange [0:35]

set xlabel "Number of Leaves"
set ylabel "Convergence Time in Seconds"

set title "Selected Topologies (Leaves - Time)"

set output "leaves_selected_time.eps"
set size 2,2
set terminal postscript eps color enhanced solid 40

plot "../data/selected_leaves_avg.txt" using 3:9 title "average" lw 5 lc 3 with lines
