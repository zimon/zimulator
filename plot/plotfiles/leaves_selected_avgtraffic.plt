#set key top left
unset key

set xrange [1:11]
set yrange [0:1]

set xlabel "Number of Leaves"
set ylabel "Average Traffic per Net in KiB"

set title "Selected Topologies (Leaves - Average Traffic per Net)"

set output "leaves_selected_avgtraffic.eps"
set size 2,2
set terminal postscript eps color enhanced solid 40

plot "../data/selected_leaves_avg.txt" using 3:19 title "average" lw 5 lc 3 with lines
