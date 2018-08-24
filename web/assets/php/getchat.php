<?php
session_start();

require_once('../classes/database.php');
require_once('../classes/bbc.php');
$config = include('../../config.php');

$lastid = isset($_SESSION["lastid"]) ? $_SESSION["lastid"] : 0;
$token = $_POST['token'];

DB::query("SELECT * FROM sc_chat WHERE id>$lastid AND token='$token' ORDER BY id");

$data = DB::getData();
if(!$data) return;

foreach($data as $row){
	$lastid = $row["id"];
	echo '<i><font color=#888>' . gmdate($config['time_format'], $row["time"]) . '</font></i> ' . BBC::parse($row["msg"]) . '<br>';
}

$_SESSION["lastid"] = $lastid;
