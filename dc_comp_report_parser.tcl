#!/usr/bin/tclsh

package require Tk

set topVerilogFile ""
set topModuleName ""

proc select_verilog_file {} {
    global topVerilogFile topModuleName

    set file [tk_getOpenFile -title "Select Top Module Verilog File" -filetypes {{"Verilog Files" ".v"}}]
    if {$file ne ""} {
        set topVerilogFile $file
        set topModuleName [file rootname [file tail $file]]
        .fileLabel configure -text "Selected Verilog File: $file"
    }
}

proc run_synthesis {} {
    global topVerilogFile topModuleName

    if {$topVerilogFile eq ""} {
        tk_messageBox -title "Error" -message "Please select a Verilog file first." -icon error
        return
    }

    file mkdir src
    file mkdir lib
    file mkdir reports
    file mkdir out
    file copy -force $topVerilogFile src/

    set script [open "dc_auto_flow.tcl" w]
    puts $script "set DESIGN_NAME $topModuleName"
    puts $script "set RTL_FILES \"$topModuleName.v\""
    puts $script "set TARGET_LIB \"typical.db\""
    puts $script "set REPORT_DIR reports"
    puts $script "set OUT_DIR out"
    puts $script "file mkdir \$REPORT_DIR"
    puts $script "file mkdir \$OUT_DIR"
    puts $script "set_app_var search_path [list ./src ./lib]"
    puts $script "set_app_var target_library [list \$TARGET_LIB]"
    puts $script "set_app_var link_library \"* \$TARGET_LIB\""
    puts $script "read_verilog \$RTL_FILES"
    puts $script "current_design \$DESIGN_NAME"
    puts $script "elaborate"
    puts $script "link"
    puts $script "check_design"
    puts $script "create_clock -period 10 [get_ports clk]"
    puts $script "set_input_delay 2 -clock clk [all_inputs]"
    puts $script "set_output_delay 2 -clock clk [all_outputs]"
    puts $script "compile_ultra -gate_clock"
    puts $script "report_area > \$REPORT_DIR/\${DESIGN_NAME}_area.rpt"
    puts $script "report_power > \$REPORT_DIR/\${DESIGN_NAME}_power.rpt"
    puts $script "report_timing -max_paths 10 > \$REPORT_DIR/\${DESIGN_NAME}_timing.rpt"
    puts $script "write -format verilog -hierarchy -output \$OUT_DIR/\${DESIGN_NAME}_synth.v"
    puts $script "write_sdf \$OUT_DIR/\${DESIGN_NAME}.sdf"
    puts $script "write_sdc \$OUT_DIR/\${DESIGN_NAME}.sdc"
    puts $script "exit"
    close $script

    if {[catch {exec dc_shell -f dc_auto_flow.tcl} result]} {
        tk_messageBox -title "Error" -message "Synthesis failed: $result" -icon error
    } else {
        tk_messageBox -title "Success" -message "Synthesis and reports generated." -icon info
    }
}

proc parse_report {type} {
    global topModuleName

    if {$topModuleName eq ""} {
        tk_messageBox -title "Error" -message "Top module name not set. Please run synthesis first." -icon error
        return
    }

    set perlCmd "perl summary.pl $topModuleName"

    if {[catch {exec sh -c $perlCmd} result]} {
        tk_messageBox -title "Error" -message "Failed to parse summary: $result" -icon error
        return
    }

    toplevel .outputWin
    wm title .outputWin "Summary Report"

    text .outputWin.textBox -height 18 -width 70 -wrap word
    scrollbar .outputWin.scroll -orient vertical -command {.outputWin.textBox yview}
    .outputWin.textBox configure -yscrollcommand {.outputWin.scroll set}

    pack .outputWin.scroll -side right -fill y
    pack .outputWin.textBox -side left -fill both -expand true -padx 10 -pady 10
    .outputWin.textBox insert end "$result\n"
    .outputWin.textBox see end

    button .outputWin.ok -text "OK" -command {destroy .outputWin}
    pack .outputWin.ok -pady 10
}

wm title . "ASIC Synthesis & Summary GUI"

label .title -text "1. Select Verilog File for Synthesis"
button .selectBtn -text "Select Verilog File" -command select_verilog_file
label .fileLabel -text "No file selected"

label .step2 -text "2. Run Synthesis"
button .synthBtn -text "Run Synthesis" -command run_synthesis

label .step3 -text "3. Parse Summary Report"
button .summaryBtn -text "Parse Summary" -command {parse_report "Summary"}

pack .title .selectBtn .fileLabel -padx 10 -pady 5
pack .step2 .synthBtn -padx 10 -pady 10
pack .step3 .summaryBtn -padx 10 -pady 10

