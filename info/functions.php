<?php
require dirname(__FILE__) . '/SourceQuery/SourceQuery.class.php';

/**
 * Common Functions for Source Server Stats
 */

function getServerInfo($config_path, $cache_path, $cache_lifetime = 10)
{
	// Load from cache if possible, bypassing other checks.
	$cache_result = readFromCache($cache_path, $cache_lifetime);

	if ($cache_result)
		return $cache_result;
	
	// Attempt to load configuration.
	if (!file_exists($config_path))
		die('Could not find configuration file at "'.$config_path.'"!');

	$config_raw = file_get_contents($config_path);
	$config = json_decode($config_raw, TRUE);

	// Generate server info from scratch.
	$server_info = array();

	foreach($config as $server_name => $server_data)
	{
		$sq = new SourceQuery();
		$sq->Connect($server_data['ip'], $server_data['port'], 1, SourceQuery::SOURCE);

		$info_row = array();
		$info_row['Info'] 			= $sq->GetInfo();
		$info_row['Info']['Name']	= $server_name;
		$info_row['Info']['IP']		= $server_data['ip'];
		$info_row['Info']['Port'] 	= $server_data['port'];
		$info_row['Players']		= $sq->GetPlayers();
		$info_row['Rules']			= $sq->GetRules();

		$server_info[$server_name] = $info_row;
	}

	// Attempt to write result to cache.
	writeToCache($server_info, $cache_path);

	return $server_info;
}

function readFromCache($cache_path, $cache_lifetime)
{
	if (!file_exists($cache_path))
		return NULL;

	$modified = filemtime($cache_path);
	$threshold = time() - $cache_lifetime;

	if ($modified < $threshold)
		return NULL;

	$cache_raw = file_get_contents($cache_path);
	return json_decode($cache_raw, TRUE);
}

function writeToCache($output, $cache_path)
{
	@touch($cache_path);
	if (!is_writable($cache_path))
		die('Cache path is not writable: "'.$cache_path.'"!');

	$json_output = json_encode($output, JSON_PRETTY_PRINT);
	file_put_contents($cache_path, $json_output);
}