set key top left

#set xrange [1:100]
set yrange [0:1000]

set xlabel "Number of Vertices"
set ylabel "Traffic in KiB"

set title "Vertices - Traffic"

set output "vertices_all_traffic.eps"
set size 2,2
set terminal postscript eps color enhanced solid 40

plot "../data/const_vertices_average.txt" using 2:18 title "Variable Vertices" lw 5 lc 3 with lines, "../data/mesh-1_average.txt" using 2:18 title "Complete-1" lw 5 lc 18 with lines, "../data/star2_average.txt" using 2:18 title "Star2" lw 5 lc 2 with lines, "../data/square_average.txt" using 2:18 title "Square" lw 5 lc 5 with lines, "../data/crown_average.txt" using 2:18 title "Crown" lw 5 lc 7 with lines, "../data/internet2_average.txt" using 2:18 title "Internet2" lw 25 lc 7 with points, "../data/arpa_average.txt" using 2:18 title "Arpa72" lw 25 lc 3 with points 
