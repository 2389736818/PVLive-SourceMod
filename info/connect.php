<?php
require 'functions.php';

$config_file = dirname(__FILE__).'/servers.json';
$servers = getServerConfig($config_file);

if (!empty($_GET['server']))
{
    $server_name = $_GET['server'];

    if (isset($servers[$server_name]))
    {
        $hostname = $servers[$server_name]['ip'];
        $port = $servers[$server_name]['port'];
    }
    else
    {
        die('Server not found!');
    }
}
elseif (!empty($_GET['host']))
{
    $hostname = $_GET['host'];

    if (!empty($_GET['port']))
        $port = (int)$_GET['port'];
    else
        $port = 27015;
}
else
{
    die('You need to specify your server\'s ip or url using "?host=yourserveraddresshere", if your server is not running on the default port for this game use "&port=yourserversporthere" after you specify your host.');
}

if (!empty($_GET['linkback']))
    $linkback = $_GET['linkback'];
else
    $linkback = 'http://www.friendshipisgaming.com/';
?>
<html lang="en">
<head>
<meta http-equiv="refresh" content="0; url=steam://connect/<?php echo $hostname.':'.$port; ?>">
<script type="text/javascript">
function Return()
{
    setTimeout(GoBack, 100) //wait 1 second before continuing
}

function GoBack()
{
    if (document.referrer == "")
        document.location.href = "<?php echo $linkback; ?>";
    else
        history.go(-1);
}
</script>
</head>
<body onload="Return()">
    You should be automatically redirected shortly!
</body>
</html>