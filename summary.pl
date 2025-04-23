#!/usr/bin/perl

use strict;
use warnings;

my $top_module = $ARGV[0] or die "Usage: perl summary.pl <top_module_name>\n";

my $area_file   = "reports/${top_module}_area.rpt";
my $power_file  = "reports/${top_module}_power.rpt";
my $timing_file = "reports/${top_module}_timing.rpt";

my ($cell_area, $net_area);
if (open my $fh, '<', $area_file) {
    while (<$fh>) {
        $cell_area = $1 if /Total\s+cell\s+area[:\s]+([\d\.]+)/i;
        $net_area  = $1 if /Total\s+area[:\s]+([\d\.]+)/i;
    }
    close $fh;
} else {
    warn "Warning: Cannot open $area_file\n";
}


my ($dynamic_power, $leakage_power);
if (open my $fh, '<', $power_file) {
    while (<$fh>) {
        $dynamic_power = $1 if /Total\s+Dynamic\s+Power\s*=\s*([\d\.\-]+\s*\w*)/i;
        $leakage_power = $1 if /Cell\s+Leakage\s+Power\s*=\s*([\d\.\-]+\s*\w*)/i;
    }
    close $fh;
} else {
    warn "Warning: Cannot open $power_file\n";
}


my ($critical_path_delay, $tns);
if (open my $fh, '<', $timing_file) {
    while (<$fh>) {
        $critical_path_delay = $1 if /data\s+arrival\s+time\s+([\d\.]+)/i;
        $tns = $1 if /Total\s+Negative\s+Slack\s*[:=]?\s*([\d\.\-]+\s*\w*)/i;
    }
    close $fh;
} else {
    warn "Warning: Cannot open $timing_file\n";
}


print "===== Synthesis Summary for $top_module =====\n";

print "\n[AREA REPORT]\n";
print "Total Cell Area: " . ($cell_area  // "N/A") . "\n";
print "Total Net Area : " . ($net_area   // "N/A") . "\n";

print "\n[POWER REPORT]\n";
print "Dynamic Power  : " . ($dynamic_power  // "N/A") . "\n";
print "Leakage Power  : " . ($leakage_power  // "N/A") . "\n";

print "\n[TIMING REPORT]\n";
print "Critical Delay : " . ($critical_path_delay  // "N/A") . " ns\n";
print "Total Neg. Slack: " . ($tns // "N/A") . "\n";

print "=============================================\n";

