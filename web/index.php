<?php
session_start();

if(file_exists('./install'))
	die('Delete the install directory to use Source Chatter.');

if(!file_exists('config.php'))
	die('Source Chatter not configured. How did you even get here?');

require_once('./assets/classes/database.php');
require_once('./assets/classes/server.php');

require('steamauth/steamauth.php');

$config = include('config.php');
?>

<!DOCTYPE html>
<html>
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
	<title>Source Chatter</title>
	<!--<link rel="stylesheet" href="./assets/css/styles.css">-->
	<link rel="stylesheet" href="./assets/css/main.css">
	<link rel="stylesheet" href="./assets/css/scoreboard.css">
	<link rel="stylesheet" href="./assets/css/chat.css">
</head>
<body>
<?php if(!isset($_SESSION['steamid'])){ ?>
	<center>
	<h2>Log in to access this webpage:</h2>
	<?php loginbutton("rectangle"); ?>
	</center>
<?php  
}else{

	$sid = $_SESSION['steamid'];
	DB::query("SELECT * FROM sc_users WHERE auth64='$sid' LIMIT 1");

	$user = DB::getRow();
	if(!$user){
		echo "<center><h2>Sorry, you do not have access to this website.</h2>";
		logoutbutton();
		echo "</center>";
	}else{
		include('steamauth/userInfo.php');
		include('chat.php');
	}
}    
?>  
</body>
</html>
