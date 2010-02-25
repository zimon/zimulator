set key top right

#set data style lines
#
set xrange [0:101]
set yrange [0:51]
set zrange [0:1000]

#set contour base
#set surface
set xlabel "Edges"
set ylabel "Vertices"
set zlabel "Traffic"

set dgrid3d 50,50,30
#show contour

f(x,y)= 0.089883648*x**2-1.5855689*x-0.024827229*y**2+2.6173149*y-9.7314087

set title "Edges and Vertices - Traffic"

set output "3d_stat_edges_vertices_traffic.eps"
set size 2,2
set terminal postscript eps color enhanced solid 40

set view 55,310

#splot f(x,y) title "Approximated Function" with lines 3, "../../data/all_average.txt" using 5:2:18 title "Interpolated Data" with lines 1
splot f(x,y) title "Approximated Function" with lines 3, "../../data/all_average.txt" using 5:2:18 title "Interpolated Data" lw 3 lc 1 with lines
