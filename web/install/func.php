<?php

function prepare($name, $creation, $isTable){
	if(exists($name, $isTable)){
		echoCheck(($isTable ? "Table" : "Event") . "\"$name\"", true);
		return true;
	}
	echo 'Creating..';
	DB::query($creation);
	echo var_dump(DB::getData());
	return exists($name);
}

function exists($name, $isTable){
	if($isTable)
		DB::query("SHOW TABLES LIKE '$name'");
	else DB::query("SHOW EVENTS WHERE name='$name'");
	$exists = !!DB::getRow();
	echoCheck($name, $exists);
	return $exists;
}

function echoCheck($name, $exists){
	echo "$name: <b>" . getCheck($exists) . "</b><br>";
}

function getCheck($t){
	if($t) return "<font color=#22cc22>Created</font>";
	else return "<font color=#ff5555>NOT Created</font>";
}

function getStatus($t){
	if($t) return "<font color=#22cc22>ON</font>";
	else return "<font color=#ff5555>OFF</font>";
}
