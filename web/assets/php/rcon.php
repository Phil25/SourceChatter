<?php
require_once('../../assets/classes/server.php');
session_start();
require __DIR__ . '/../../SourceQuery/bootstrap.php';

use xPaw\SourceQuery\SourceQuery;

// For the sake of this example
Header('Content-Type: text/plain');
Header('X-Content-Type-Options: nosniff');

define('SQ_TIMEOUT',     1);
define('SQ_ENGINE',      SourceQuery::SOURCE);

$Query = new SourceQuery();

try{
	$token = 'server_' . $_POST['token'];
	$Query->Connect($_SESSION[$token]->getIP(), $_SESSION[$token]->getPort(), SQ_TIMEOUT, SQ_ENGINE);
	$Query->SetRconPassword($_SESSION[$token]->getPassword());
	
	$color = str_replace(';', '', $_SESSION["tag_color"]);
	$tag = str_replace(';', '', $_SESSION["tag"]);
	$flags = $_SESSION["flags"];
	$name = str_replace(';', '', $_SESSION["profile_name"]);
	$msg = str_replace(';', '', $_POST["msg"]);

	$steamid64 = $_SESSION['steamid'];
	echo $Query->Rcon('say_as "' . $color . '" "' . $tag . '" "' . $name . '" "' . $flags . '" ' . $msg);
}catch(Exception $e){
	echo $e->getMessage();
}finally{
	$Query->Disconnect();
}

?>
