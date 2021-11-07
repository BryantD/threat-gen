<?php

if ($_POST['tank'] && $_POST['class'] && $_FILES) {
	// Initialize stuff

	$hacker = 0;

	// Snag CGI

	$tank = $_POST['tank'];
	$class = $_POST['class'];
	$tpoints = $_POST['talent'];
	$you = $_POST['you'] || 0;

	$threattype = 	($_POST['specials'] ? "s" : "") . 
			($_POST['white']    ? "w" : "") .
			($_POST['other']    ? "o" : "") .
			($_POST['gear']     ? "g" : "");
	if (! $threattype) {
		$threattype = "swog";
	}

	$etank = escapeshellarg($tank);

	if ($class != "Druid" && $class != "Paladin" && $class != "Warrior") {
		$hacker = 1;
	}

	// Set up filesystem stuff

	$basedir = dirname($_SERVER['SCRIPT_FILENAME']);
	$datafile = $basedir . "/data/" . basename(tempnam("/tmp", "tc"));

	// Generate gen-data args

	$scriptargs = ' -c ' . $class . ' -t ' . $etank . ' -' . $tpoints . ' -' . $threattype;
	if ($class == "Warrior") {
		$scriptargs .= ' -h ';
	}
	$scriptargs .= $_FILES['combatlog']['tmp_name'] . ' > ' . $datafile;

	if (! $hacker) {
		// Run the data script

		if ($you) {
			exec('cat ' . $datafile . ' | ' . $basedir . '/bin/you.sh ' . $etank . ' > ' . $datafile . '.tmp');
			rename($datafile . '.tmp', $datafile);
		}

		exec($basedir . '/bin/gen-data.pl ' . $scriptargs);

		include_once $basedir . '/php-ofc-library/open_flash_chart_object.php';

		// Show the graphs

		open_flash_chart_object( "100%", 600, 'http://'. $_SERVER['SERVER_NAME'] . '/' . dirname($_SERVER['PHP_SELF']) . '/threat-data.php?tank=' . $tank . '&data=' . $datafile );
		open_flash_chart_object( "100%", 600, 'http://'. $_SERVER['SERVER_NAME'] . '/' . dirname($_SERVER['PHP_SELF']) . '/damage-data.php?tank=' . $tank . '&data=' . $datafile );
		echo "<p>./bin/gen-data.pl " .  $scriptargs . "</p>";
	}
}
else {
	// Small JavaScript bit
	echo <<<END
<script type='text/javascript'>
<!--

function updateTalent(class)
{
	var talentName;
	if (class == 'Warrior') {
		talentName = 'Defiance';
	}
	if (class == 'Druid') {
		talentName = 'Feral Instinct';
	}
	if (class == 'Paladin') {
		talentName = 'Improved Righteous Fury';
	}
	document.getElementById('talent-type').firstChild.nodeValue = talentName;
}
// -->
</script>
END;

	// Form proper
	echo <<<END
<form enctype='multipart/form-data' method='POST'>
	<input type='hidden' name='MAX_FILE_SIZE' value='3000000' />

	<div class="threatrow">
		<span class="threatlabel"><strong>Tank:</strong></span>
		<span class="threatformw"><input name='tank' type='text' /></span>
	</div>

	<div class="threatrow">
		<span class="threatlabel"><strong>Class:</strong> </span>
		<span class="threatformw"><select name='class' onchange='updateTalent(this.value)' >
			<option>Druid</option>
			<option>Paladin</option>
			<option>Warrior</option>
		</select></span>
	</div>

	<div class="threatrow">
		<span class="threatlabel"><strong>Talent Points:</strong> </span>
		<span class="threatformw"><select name='talent'>
			<option>0</option>
			<option>1</option>
			<option>2</option>
			<option selected>3</option>
		</select> (<span id='talent-type'>Feral Instinct</span>)</span>
	</div>

	<div class="threatrow">
		<span class="threatlabel"><strong>Threat Sources:</strong></span>
		<span class="threatformw"><table cellpadding="0" cellspacing="0"><tr><td>Special </td><td class="threattable"><input name='specials' type='checkbox' checked/></td> <td>Melee </td><td class="threattable"><input name='white' type='checkbox' checked/></td><tr>
		<td>Healing/Other </td><td class="threattable"><input name='other' type='checkbox' checked/></td> <td>Gear </td><td class="threattable"><input name='gear' type='checkbox' checked/></td></tr></table></span>
	</div>

	<div class="threatrow">
		<span class="threatlabel"><strong>Log:</strong> </span>
		<span class="threatformw"><input name='combatlog' type='file' /></span>
	</div>

	<div class="threatrow">
		<span class="threatlabel">&nbsp;</span>
		<span class="threatformw"><input name='you' type='checkbox' /> I captured this log</span>
	</div>

	<div class="threatrow">
		<span class="threatformw"><input type='submit'  value='Send'/></span>
	</div>
  <div class="spacer">
  &nbsp;
  </div>
</form>
END;
}
?>
