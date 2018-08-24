<?php 
class Server{
	private $token;
	private $server_name;
	private $ip;
	private $port;
	private $password;

	function __construct($token, $server_name, $ip, $port, $password){
		$this->token = $token;
		$this->server_name = $server_name;
		$this->ip = $ip;
		$this->port = $port;
		$this->password = $password;
	}

	public function getToken(){
		return $this->token;
	}

	public function getServerName(){
		return $this->server_name;
	}

	public function getIP(){
		return $this->ip;
	}

	public function getPort(){
		return $this->port;
	}

	public function getPassword(){
		return $this->password;
	}
}
?> 
