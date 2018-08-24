<?php
require_once('../classes/database.php');

$config = include('../../config.php');
$token = $_POST['token'];

DB::query("SELECT * FROM sc_players WHERE token='$token' ORDER BY team DESC, score DESC");

$colors = $config['team_colors'];
$data = DB::getData();
if(!$data) return;

foreach($data as $row)
	format_player($row);

function format_player($i){
	format_player_ex($i["auth64"], $i["team"], $i["name"], $i["class"], $i["score"], $i["status"], $i["userid"], $i["ping"], $i["country"]);
}

function format_player_ex($auth, $team, $name, $class, $score, $status, $userid, $ping, $country){
	global $colors;
	$profile_page = 'https://steamcommunity.com/profiles/' . $auth . '/';
	$x = new SimpleXmlElement(file_get_contents($profile_page . '?xml=1'));

	echo '<div class="player" style="border-color: #' . $colors[$team] . '">';

	echo '<div class="profile">';
		echo '<a target="_blank" href="' . $profile_page . '"><img src="' . $x->avatarIcon . '"></a>';
		echo '<b><a target="_blank" href="' . $profile_page . '" style="color: #' . $colors[$team] . '">' . $name . '</a></b>';
		echo '<i>[' . $country . ']</i>';
	echo '</div>';

	echo '<div class="info">';
		echo '<span>' . format_status($status) . '</span>';
		echo '<span><i>#' . $userid . '</i></span>';
		echo '<span>' . get_class_emblem($team, $class) . '</span>';
		echo '<span>' . $score . '</span>';
		echo '<span><b><font class="ping" color=#' . get_ping_color($ping) . '>' . $ping . '</font></b></span>';
	echo '</div>';

	echo '</div>';
}

function format_status($status){
	global $config;
	$statuses = '';
	if($status & 4) // is speaking
		$statuses .= '<span><img src="../assets/img/speech.png"></span>';
	if($status & 2) // is dead
		$statuses .= '<span><img src="../assets/img/dead.png"></span>';
	if($status & 1) // is in group
		$statuses .= '<span><img src="'.$config['group_path'].'"></span>';
	return $statuses;
}

function get_class_emblem($team, $class){
	if($team < 2) return '';
	if($class == 0) return '';
	return '<img src="../assets/img/class_' . $team . '_' . $class . '.png">';
}

function get_ping_color($val){
	if($val < 40) return '00ff00';
	if($val < 70) return '7fff00';
	if($val < 90) return 'ffff00';
	return 'ff0000';
}

?>
