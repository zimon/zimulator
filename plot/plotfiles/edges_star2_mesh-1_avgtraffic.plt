set key top left

#set xrange [1:16]
#set yrange [0:35]

set xlabel "Number of Edges"
set ylabel "Average Traffic per Net in KiB"

set title "Complete and Star2 Topologies (Edges - Average Traffic per Net)"

set output "edges_star2_mesh-1_avgtraffic.eps"
set size 2,2
set terminal postscript eps color enhanced solid 40

plot "../data/mesh-1_average.txt" using 5:19 title "Complete-1" lw 5 lc 18 with lines, "../data/star2_average.txt" using 5:19 title "Star2" lw 5 lc 2 with lines
