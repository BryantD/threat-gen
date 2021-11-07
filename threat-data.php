<?php

$one_sec = array();
$five_sec = array();
$ten_sec = array();
$overall = array();

$x_lab = array();

$handle = fopen($_GET['data'], "r");

while (!feof($handle)) {
	$l = fgets($handle);
	$l = rtrim($l);
	$line = explode("\t", $l);

	$x_labels[] = $line[0];

	$one_sec[] = $line[1];
	$five_sec[] = $line[2];
	$ten_sec[] = $line[3];
	$overall[] = $line[4];

	$one_sec_max = max($line[1], $one_sec_max);
	$one_sec_min = min($line[1], $one_sec_min);
	
	$five_sec_max = max($line[2], $five_sec_max);
	$five_sec_min = min($line[2], $five_sec_min);
	
	$ten_sec_max = max($line[3], $ten_sec_max);
	$ten_sec_min = min($line[3], $ten_sec_min);
	
	$overall_max = max($line[4], $overall_max);
	$overall_min = min($line[4], $overall_min);
}

fclose($handle);

// use the chart class to build the chart:
include_once( 'php-ofc-library/open-flash-chart.php' );
$g = new graph();

$g->title($_GET['tank'] . ' Threat', '{font-size: 26px;}');

$g->set_data( $overall );
$g->set_data( $ten_sec );
$g->line(2, '0x00cc00', 'Overall TPS', 10);
$g->line(1, '0x0033ff', '10 Sec. TPS', 10);

// set the Y max

$y_max = (floor($ten_sec_max / 50) + 1) * 50;
$g->set_y_max( $y_max );
$g->y_label_steps( $y_max / 100 );

$g->set_x_labels( $x_labels );
$g->set_x_label_style(10, '#9933CC', 0, 50, '#00A000' );
$g->set_x_axis_steps(50);

$g->bg_colour = '#eeeeee';
// display the data
echo $g->render();
?>
