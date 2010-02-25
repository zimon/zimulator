set key top right

set xrange [0:16]
set yrange [0:51]
set zrange [0:35]

#set data style lines
#set contour base
#set surface
set xlabel "Diameter"
set ylabel "Inner Vertices"
set zlabel "Time"

f(x,y)= x+0.2163*y+5.1883
#f(x,y)=a*x**3*y**3+b*x**2*y**2+c*x*y+sing 1:5:19 via b

set dgrid3d 50,50,30
#show contour

set title "Diameter and Inner Vertices - Time"

set output "3d_stat_diameter_ivertices_time.eps"
set size 2,2
set terminal postscript eps color enhanced solid 40

unset pm3d

set view 55,310

splot f(x,y) title "Approximated Function" with lines 3, "../../data/all_average.txt" using 1:4:9 title "Interpolated Data" lw 3 lc 1 with lines
#splot f(x,y) title "approximated function" with lines 3, "../../data/all_average.txt" using 1:4:9 title "interpolated data" with lines 1
