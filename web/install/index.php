<?php

if(!file_exists('../config.php'))
	die('config.php not found. Please rename config.template.php found in root directory of Source Chatter to config.php and configure it appropriately.');

require_once('../assets/classes/database.php');
$config = include('../config.php');
DB::connect($config);

?>

<!DOCTYPE html>
<html>
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
	<title>Source Chatter Installer</title>
</head>
<body>
<center>
<h2>Source Chatter Installation</h2>
<?php

include('func.php');
$creations = include('tables.php');
$tables = array_keys($creations);

foreach($tables as $table)
	DB::query($creations[$table]);

DB::query(
	"CREATE EVENT `sc_clear_chat` 
	ON SCHEDULE EVERY 5 MINUTE 
	ON COMPLETION NOT PRESERVE ENABLE DO 
	DELETE FROM sc_chat WHERE time < UNIX_TIMESTAMP(DATE_SUB(NOW(), INTERVAL 5 MINUTE))"
);

$ready = true;

echo "<br><u>Tables</u><br>";
foreach($tables as $table)
	$ready &= exists($table, true);

echo "<br><u>Events</u><br>";
$ready &= exists("sc_clear_chat", false);

if(!$ready)
	die('Something went wrong. Check your configuration and try again. Make sure the database user has privileges');

echo "<br><u>Variables</u><br>";
DB::query("SET GLOBAL event_scheduler = ON"); // will probably fail
DB::query("SHOW VARIABLES WHERE variable_name='event_scheduler'");
$esrow = DB::getRow();
if(!$esrow)
	echo 'There was a problem reading Event Sheduler status.';
else{
	$eson = $esrow['Value'] === 'ON';
	echo "Event Scheduler: <b>" . getStatus($eson) . "</b><br>";
	if(!$eson)
		echo "<font color=#aa2222><b><u>WARNING</u></b>: Event Sheduler is OFF.<br>This means that old chat messages won't be automatically deleted.<br>You may use Source Chatter without it but it's recommended that you or your database provider turn it on.<br></font>";
}

?>

<br>
Installation completed successfully.
<br>
Delete the <i>install</i> folder to use Source Chatter.
<br>
<br>
More information:
<br>
<a target="_blank" href="about:blank">AlliedModders Thread</a>
<a target="_blank" href="https://github.com/Phil25/SourceChatter/">GitHub Repo</a>
</center>
</body>
</html>
