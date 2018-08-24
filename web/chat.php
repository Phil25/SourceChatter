<?php
$_SESSION['tag_color'] = $user['tag_color'];
$_SESSION['tag'] = $user['tag'];
$_SESSION['flags'] = $user['flags'];
$_SESSION['profile_name'] = $steamprofile['personaname'];

unset($_SESSION["lastid"]);
$servers = $config['servers'];

?>

<div class="split left">
	<div id="chat" style="overflow-y: scroll; height:60vh"></div>

	<br><br>
	<?php echo "<b><font color=#" . $user['tag_color'] . ">" . $user['tag'] . "</font><font color=#147500>" . $steamprofile['personaname'] . "</font></b>: "; ?>
	<input id="rcon_field" type="text" placeholder="Type your message..." style="width:45%;" />
	<input id="rcon_button" type="button" value="Send"/>
	<select onchange="updateServers()" id="servers">
	<?php foreach($servers as $s){
		$_SESSION['server_' . $s['token']] = new Server($s['token'], $s['name'], $s['ip'], $s['port'], $s['password']);
		echo '<option value="' . $s['token'] . '">' . $s['name'] . '</option>';
	} ?>
	</select>
	<br><textarea id="rcon_response" readonly placeholder="Last command output..." style="width:95%;height:20vh"></textarea>

	<br>
	<?php logoutbutton(); ?>
</div>

<div class="split right">
	<div id="players"></div>
</div>

<script src="assets/js/func.js"></script>
