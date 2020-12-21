#stdbuf -o0 /usr/local/bin/ipsec-secgw --lcores=3 -n 1 --vdev="net_tap0,mac=fixed" fm1-mac1  -- -p 0x3 -u 1 -P --config="(0,0,3),(1,0,3)" -w 300 -l -f ./ep.cfg > ./ipsec-secgw.out1 2>&1 &
#stdbuf -o0 /usr/local/bin/ipsec-secgw --lcores=3 -n 1 --vdev="net_tap0,mac=fixed" --vdev="net_tap1,mac=fixed" --vdev="net_tap2,mac=fixed" --vdev="net_tap3,mac=fixed" \
#    -- -p 0xff -u 1 -P --config="(0,0,3),(1,0,3),(2,0,3),(3,0,3),(4,0,3),(5,0,3),(6,0,3),(7,0,3)" -w 300 -l -f ./ep.cfg
#tap
stdbuf -o0 ipsec-secgw --lcores=3 -n 1 --vdev="net_tap0,mac=fixed" --vdev="net_tap1,mac=fixed" --vdev="net_tap2,mac=fixed" --vdev="net_tap3,mac=fixed" \
    -- -p 0xff -u 0xf -P --config="(0,0,3),(1,0,3),(2,0,3),(3,0,3),(4,0,3),(5,0,3),(6,0,3),(7,0,3)" --rxoffload=0xff --txoffload=0xff -w 300 -l -f ./ep.cfg

#kni
#stdbuf -o0 ipsec-secgw --lcores=1-3 -n 1 --vdev="net_kni0" --vdev="net_kni1" --vdev="net_kni2" --vdev="net_kni3" \
#    -- -p 0xff -u 0xf -P --config="(0,0,1),(1,0,2),(2,0,3),(3,0,1),(4,0,2),(5,0,3),(6,0,2),(7,0,3)" -w 300 -l -f ./ep.cfg
