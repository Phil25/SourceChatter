var rconfield = document.getElementById("rcon_field");
var rconbutton = document.getElementById("rcon_button");
var rconresponse = document.getElementById("rcon_response");
var servers = document.getElementById("servers");
var chatbox = document.getElementById("chat");
var playerbox = document.getElementById("players");
var server_token = "10x";

function updateServers(){
	server_token = servers.value;
	chatbox.innerHTML = "";

	var xmlhttp = new XMLHttpRequest();
	xmlhttp.open("GET", "../assets/php/resetlastid.php", true);
	xmlhttp.send();
}

function updateChat(){
	if(!(this.readyState == 4 && this.status == 200))
		return;

	if(this.responseText.length === 0)
		return;

	let atBottom = isAtBottom(chatbox);
	chatbox.insertAdjacentHTML('beforeend', this.responseText);
	if(atBottom) chatbox.scrollTop = chatbox.scrollHeight;
}

function isAtBottom(obj){
	let dist = obj.scrollHeight -obj.offsetHeight -obj.scrollTop;
	return (dist < 5);
}

function updatePlayers(){
	if(!(this.readyState == 4 && this.status == 200))
		return;

	playerbox.innerHTML = this.responseText;
	playerbox.scrollTop = playerbox.scrollHeight;
}

function commandResponse(){
	if(!(this.readyState == 4 && this.status == 200))
		return;
	
	rconresponse.innerHTML = this.responseText;
	rconresponse.scrollTop = rconresponse.scrollHeight;
}

function getChat(){
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.onreadystatechange = updateChat;
	xmlhttp.open("POST", "../assets/php/getchat.php", true);
	xmlhttp.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
	
	var params = 'token=' + server_token;
	xmlhttp.send(params);
}

function getPlayers(){
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.onreadystatechange = updatePlayers;
	xmlhttp.open("POST", "../assets/php/getplayers.php", true);
	xmlhttp.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
	
	var params = 'token=' + server_token;
	xmlhttp.send(params);
}

function sendRcon(){
	var xmlhttp = new XMLHttpRequest();
	xmlhttp.onreadystatechange = commandResponse;
	xmlhttp.open("POST", "../assets/php/rcon.php", true);
	xmlhttp.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");

	var params = 'msg=' + rconfield.value + '&token=' + server_token;
	rconfield.value = "";

	xmlhttp.send(params);
}

rconbutton.onclick = sendRcon;
rconfield.addEventListener("keyup", function(event){
	if(event.key === "Enter"){
		sendRcon();
	}
});

setInterval(getChat, 1000);
setInterval(getPlayers, 1000);
