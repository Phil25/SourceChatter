<?php

return array(
	'host' => 'localhost',
	'user' => 'username',
	'pass' => 'password',
	'dbname' => 'database_name',
	'port' => '3306',
	'apikey' => 'XXXXXXXXXXXXXX', // your Steam API key (https://steamcommunity.com/dev/apikey)
	'domainname' => 'www.example.com', // URL of your website displayed in the steamcommunity login page
	'time_format' => 'i:s', // timestamp formatting (http://php.net/manual/en/function.date.php)
	'group_path' => '../assets/img/group.png', // group emblem icon path relative to assets/php/ directory, leave blank if unused

	'team_colors' => array("222222", "b2b2b2", "c40000", "004aff"), // colors of each team in hex (in TF2: none, spec, red, blu)

	// configure servers AFTER having installed the plugin
	'servers' => array(
		'server1' => array( // server1 can be anything
			'token' => 'token1', // token of the server matching sm_sourcechatter_token cvar
			'name' => 'Server Name', // name of the server, prefably short
			'ip' => '0.0.0.0', // localhost or 127.0.0.1 does not work
			'port' => '27015',
			'password' => 'xxxxxxxx' // rcon password
		),
		'server2' => array(
			'token' => '',
			'name' => '',
			'ip' => '',
			'port' => '',
			'password' => ''
		)
	)
);
