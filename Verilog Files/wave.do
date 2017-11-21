#set the working dir, where all compiled verilog goes
vlib work

#compile all veriolog modules in mux.v to working dir 
#could also have multiple veriolog files
vlog finalProject.v

#load simulation using mux as the top level simulation module
vsim finalProject

#log all signals and add some signals to waveform window
log {/*}

# add wave {/*} would add all items in top level simulation module
add wave -r /*

force {CLOCK_50} 0 0ns, 1 {10ns} -r 20ns

#initial
force {KEY[0]} 1	
force {KEY[1]} 1


#reset
force {KEY[0]} 1	
run 30ns
force {KEY[0]} 0
run 30ns 
force {KEY[0]} 1
run 30ns

#go
#reset
force {KEY[1]} 1	
run 30ns
force {KEY[1]} 0
run 30ns 
force {KEY[1]} 1
run 30ns

run 1500000ns