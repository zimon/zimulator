set key top left

set xrange [1:16]
set yrange [0:800]

set xlabel "Diameter"
set ylabel "Traffic in KiB"

set title "Circle, Row, Square and Crown Topologies (Diameter - Traffic)"

set output "diameter_all_traffic.eps"
set size 2,2
set terminal postscript eps color enhanced solid 40

plot "../data/circle_even_average.txt" using 1:18 title "Circle" lw 5 lc 1 with lines, "../data/row_average.txt" using 1:18 title "Row" lw 5 lc 3 with lines, "../data/square_average.txt" using 1:18 title "Square" lw 5 lc 5 with lines, "../data/crown_average.txt" using 1:18 title "Crown" lw 5 lc 7 with lines, "../data/internet2_average.txt" using 1:18 title "Internet2" lw 25 lc 7 with points, "../data/arpa_average.txt" using 1:18 title "Arpa72" lw 25 lc 3 with points

