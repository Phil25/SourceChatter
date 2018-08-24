<?php
return array(
'sc_chat' => "CREATE TABLE IF NOT EXISTS `sc_chat` (
	`id` int(11) NOT NULL AUTO_INCREMENT,
	`token` varchar(16) COLLATE utf8_unicode_ci DEFAULT 'none',
	`time` int(11) NOT NULL,
	`msg` varchar(511) COLLATE utf8_unicode_ci NOT NULL,
	PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci",

'sc_players' => "CREATE TABLE IF NOT EXISTS `sc_players` (
	`id` int(8) NOT NULL AUTO_INCREMENT,
	`userid` int(8) NOT NULL,
	`token` varchar(16) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'none',
	`auth64` bigint(24) NOT NULL,
	`ip` varchar(16) COLLATE utf8_unicode_ci NOT NULL,
	`name` varchar(64) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'unconnected',
	`team` int(4) NOT NULL DEFAULT '0',
	`score` int(8) NOT NULL DEFAULT '0',
	`class` int(4) NOT NULL DEFAULT '0',
	`status` int(11) NOT NULL DEFAULT '0',
	`ping` int(8) DEFAULT NULL,
	`country` varchar(8) COLLATE utf8_unicode_ci DEFAULT NULL,
	PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci",

'sc_users' => "CREATE TABLE IF NOT EXISTS `sc_users` (
	`auth64` bigint(24) NOT NULL,
	`flags` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL COMMENT 'SourceMod admin flags',
	`name` varchar(32) COLLATE utf8_unicode_ci DEFAULT NULL COMMENT 'Unused',
	`tag` varchar(16) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
	`tag_color` varchar(8) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'ffffff' COMMENT 'in hex',
	`added_by` bigint(24) DEFAULT NULL,
	PRIMARY KEY (`auth64`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci"

);
