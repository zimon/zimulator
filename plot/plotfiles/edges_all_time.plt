set key top left
#unset key

set xrange [0:80]
set yrange [0:35]

set xlabel "Number of Edges"
set ylabel "Convergence Time in Seconds"

set title "Edges - Time"

set output "edges_all_time.eps"
set size 2,2
set terminal postscript eps color enhanced solid 40

plot  "../data/const_edges_avg.txt" using 5:9 title "Variable Edges" lw 5 lc 3 with lines, "../data/mesh-1_average.txt" using 5:9 title "Complete-1" lw 5 lc 18 with lines, "../data/star2_average.txt" using 5:9 title "Star2" lw 5 lc 2 with lines, "../data/square_average.txt" using 5:9 title "Square" lw 5 lc 5 with lines, "../data/crown_average.txt" using 5:9 title "Crown" lw 5 lc 7 with lines, "../data/internet2_average.txt" using 5:9 title "Internet2" lw 25 lc 7 with points, "../data/arpa_average.txt" using 5:9 title "Arpa72" lw 25 lc 3 with points

