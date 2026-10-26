# Find the lab folder relative to this script.
set lab_dir [file normalize [file join [file dirname [info script]] ..]]

# Use a separate folder to preserve the existing project.
create_project ECE520_Lab3_BRAM_FIFO \
    "$lab_dir/vivado_demo" -part xc7z010clg400-1

# Add design, testbench, and simulation data.
add_files "$lab_dir/src/sc_fifo.v"
add_files -fileset sim_1 "$lab_dir/sim/tb_sc_fifo.v"
add_files -fileset sim_1 "$lab_dir/sim/input_data.txt"

# Set the top modules.
set_property top sc_fifo [get_filesets sources_1]
set_property top tb_sc_fifo [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# Run synthesis.
launch_runs synth_1 -jobs 4
wait_on_run synth_1
open_run synth_1

# Save reports.
file mkdir "$lab_dir/reports"

report_utilization \
    -file "$lab_dir/reports/resource_utilization.rpt"

file copy -force \
    "[get_property DIRECTORY [get_runs synth_1]]/runme.log" \
    "$lab_dir/reports/synthesis.log"

# Run the simulation to completion.
launch_simulation
run all
