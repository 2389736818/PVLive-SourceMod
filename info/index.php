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
		$all_servers = array($server => $all_servers[$server]);
	else
		die('Invalid server specified!');
}
?>
<html lang="en">
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
	<link rel="stylesheet" href="style.css" media="all">
</head>
<body>
<? foreach($all_servers as $server_key => $server): ?>
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
	<div class="btn_wrapper">
		<a class="btn_custom" href="./connect.php?server=<?=$server_key ?>">
			JOIN THIS SERVER
		</a>
	</div>
</div>
<? endforeach; ?>
</body>
</html>