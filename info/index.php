<?php 
require 'functions.php';

$config_file = dirname(__FILE__).'/servers.json';
$cache_file = dirname(__FILE__).'/cache.json';
$cache_lifetime = 10;

$all_servers = getServerInfo($config_file, $cache_file, $cache_lifetime);

// Only show one single server if specified, otherwise show all servers.
if (!empty($_GET['server']))
{
	$server = $_GET['server'];
	if (isset($all_servers[$server]))
		$all_servers = array($all_servers[$server]);
	else
		die('Invalid server specified!');
}
?>
<html lang="en">
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
	<style type="text/css">
		body						{ margin: 0; padding: 0; }
		img							{ border: none; }
		div.global					{ border-style:solid; border-width:1px; font-family: Arial, Helvetica, sans-serif; font-size:11px; padding:0; overflow:hidden;}
		div.global					{ width:198px; height:286px; background-color:#6d82a2; color:#FFFFFF; border-color:#bcd4e3; }
		div.global a				{ color:#659188; text-decoration:none; }
		div.global table			{ border-collapse:collapse; padding:0; }
		.item_color_link			{ color:#659188; cursor:pointer; }
		.item_float_left			{ float:left; font-weight: bold; }
		.item_float_right			{ float:right; }
		.item_float_clear			{ clear:both; height:0px; font-size:0px; line-height:0px; }

		div.info_line				{ margin:2px 4px; height:14px; overflow:hidden; }
		div.info_line_right			{ float:right; overflow:hidden; }

		div.server_name				{ margin:2px; height:28px; padding:2px; border:solid; border-width:1px; overflow:hidden; font-weight:bold; }
		div.server_name				{ width:188px; background-color:#f3f7fa; border-color:#bcd4e3; color:#000000; }

		div.scrollable				{ margin:2px; height:100px; padding:2px; border:solid; border-width:1px; overflow-x:hidden; overflow-y:auto; position:relative; color:#202020; width:188px; background-color:#f3f7fa; border-color:#bcd4e3; }
		div.scrollable_on_c01		{ float:left; white-space:nowrap; width:21px; overflow:hidden; }
		div.scrollable_on_c02		{ float:left; white-space:nowrap; width:104px; overflow:hidden; }
		div.scrollable_on_c03		{ float:right; white-space:nowrap; text-align:right; }

		div.channelViewScrollable	{ height:155px; }

		span.server_status			{
			display:inline-block; 
			position:relative; 
			top:1px; 
			width:8px; 
			height:8px;
			border-radius:4px;
			border:1px solid black;
			box-shadow:inset 0px 0px 1px 1px #02BC00;
		}
		span.server_status.online 	{
			background-color: #9fff7d;
		}
		span.server_status.offline	{
			background-color: #ff7d9f;
		}
		
		span.btn_custom				{ text-decoration:none; font-size:11px; height:16px; line-height:16px; border:solid; border-width:1px; overflow:hidden; text-align:center; cursor:pointer; font-weight:bold; color:#659188; border-color:#669288; background-color:#bcd4e3; padding:0px 4px; }
	</style>
</head>
<body>
<? foreach($all_servers as $server): ?>
<div class="global">
	<div class="server_name">
	<?
	if ($server['Rules'])
		echo $server['Info']['HostName'];
	else
		echo $server['Info']['Name'];
	?>
	</div>
	<div class="info_line">
		<div class="item_float_left">IP:</div>
		<div class="item_float_right">
			<span class="server_status <?=(($server['Rules']) ? 'online' : 'offline') ?>">&nbsp;</span>
			<?=$server['Info']['IP'] ?>:<?=$server['Info']['Port'] ?>
		</div>
		<div class="item_float_clear"></div>
	</div>
	<div class="info_line">
		<div class="item_float_left">Players:</div>
		<div class="item_float_right">
			<?php
			if($server['Rules'])
				echo $server['Info']['Players']."/".$server['Info']['MaxPlayers'];
			else
				echo '?/?';
			?>
		</div>
		<div class="item_float_clear"></div>
	</div>
	<div class="info_line">
		<div class="item_float_left">Map:</div>
		<div class="info_line_right">
			<?php
			if ($server['Rules'])
				echo $server['Info']['Map'];
			else
				echo '?';
			?>
		</div>
		<div class="item_float_clear"></div>
	</div>

	<div class="info_line">
		<b>Online Players:</b>
	</div>
	<div class="scrollable channelViewScrollable">
		<? if ($server['Rules']): ?>
			<?
			$i = 0;
			foreach($server['Players'] as $Player_Data): ?>
			<div class="scrollable_on_c01">
				<?php echo ++$i; ?>
			</div>
			<div class="scrollable_on_c02">
				<?php echo $Player_Data['Name']; ?>
			</div>
			<div class="scrollable_on_c03">
				<?php echo $Player_Data['Frags']; ?>
			</div>
			<div class="item_float_clear">
			</div>
			<? endforeach; ?>
		<? endif; ?>
	</div>
	<div style="text-align:center; padding:2px 0px 6px 0px;">
		<a href="./connect.php?<?=http_build_query(array('host' => $server['Info']['IP'], 'port' => $server['Info']['Port'])) ?>"><span class="btn_custom">
			JOIN THIS SERVER
		</span>
		</a>
	</div>
</div>
<? endforeach; ?>
</body>
</html>